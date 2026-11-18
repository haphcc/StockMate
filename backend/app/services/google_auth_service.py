"""Owner: TV4 - LB / TV1 - Phuoc.

Google OAuth 2.0 authentication service for StockMate.
Verifies Google ID Token (or OAuth Access Token for Flutter Web),
handles seamless account linking, and provisions new customer accounts atomically.
"""

import logging
import secrets
from decimal import Decimal
from typing import Any

import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import AppException, UnauthorizedException
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.schemas.auth import TokenResponse
from app.services.auth_service import (
    ACCOUNT_NUMBER_ATTEMPTS,
    INITIAL_CASH,
    ensure_active,
    generate_account_number,
    issue_tokens,
)

logger = logging.getLogger(__name__)

GOOGLE_OAUTH_PASSWORD_SENTINEL = "GOOGLE_OAUTH_ACCOUNT"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"
GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"
GOOGLE_HTTP_TIMEOUT_SECONDS = 8


def _allowed_client_ids() -> list[str]:
    return [cid.strip() for cid in settings.GOOGLE_CLIENT_ID.split(",") if cid.strip()]


def verify_google_id_token(token: str) -> dict[str, Any]:
    """Verify a Google ID token against Google's public certs and return its claims."""
    allowed_ids = _allowed_client_ids()
    audience: str | list[str] | None
    if len(allowed_ids) == 1:
        audience = allowed_ids[0]
    elif len(allowed_ids) > 1:
        audience = allowed_ids
    else:
        audience = None

    try:
        request = google_requests.Request()
        payload = id_token.verify_oauth2_token(token, request, audience=audience)
        return dict(payload)
    except ValueError as exc:
        logger.warning("Invalid Google ID token: %s", exc)
        raise UnauthorizedException(
            "Google ID Token không hợp lệ hoặc đã hết hạn.",
            code="INVALID_GOOGLE_TOKEN",
        ) from exc
    except Exception as exc:
        logger.error("Error validating Google ID token: %s", exc)
        raise AppException(
            500,
            "GOOGLE_AUTH_ERROR",
            "Không thể xác thực với dịch vụ Google.",
        ) from exc


def verify_google_access_token(access_token: str) -> dict[str, Any]:
    """Verify a Google OAuth access token (Flutter Web fallback) via Google APIs."""
    allowed_ids = _allowed_client_ids()
    try:
        if allowed_ids:
            info_res = requests.get(
                GOOGLE_TOKENINFO_URL,
                params={"access_token": access_token},
                timeout=GOOGLE_HTTP_TIMEOUT_SECONDS,
            )
            if info_res.status_code != 200:
                raise UnauthorizedException(
                    "Google Access Token không hợp lệ hoặc đã hết hạn.",
                    code="INVALID_GOOGLE_TOKEN",
                )
            token_info = info_res.json()
            aud = str(token_info.get("aud") or token_info.get("azp") or "")
            if aud not in allowed_ids:
                raise UnauthorizedException(
                    "Google Access Token không thuộc ứng dụng này.",
                    code="INVALID_GOOGLE_TOKEN",
                )

        userinfo_res = requests.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=GOOGLE_HTTP_TIMEOUT_SECONDS,
        )
        if userinfo_res.status_code != 200:
            raise UnauthorizedException(
                "Google Access Token không hợp lệ hoặc đã hết hạn.",
                code="INVALID_GOOGLE_TOKEN",
            )
        return dict(userinfo_res.json())
    except UnauthorizedException:
        raise
    except Exception as exc:
        logger.error("Error validating Google access token: %s", exc)
        raise AppException(
            500,
            "GOOGLE_AUTH_ERROR",
            "Không thể xác thực với dịch vụ Google.",
        ) from exc


def _find_customer(db: Session, email: str, google_sub: str) -> Customer | None:
    if google_sub:
        customer = db.scalar(select(Customer).where(Customer.google_id == google_sub))
        if customer is not None:
            return customer
    return db.scalar(select(Customer).where(func.lower(Customer.email) == email))


def _sanitize_avatar_url(avatar_url: object) -> str | None:
    if not isinstance(avatar_url, str):
        return None
    cleaned = avatar_url.strip()
    if not cleaned or len(cleaned) > 255:
        return None
    return cleaned


def _build_phone_sentinel(google_sub: str) -> str:
    clean_sub = "".join(ch for ch in google_sub if ch.isalnum())
    sub_suffix = clean_sub[-9:] if len(clean_sub) >= 9 else clean_sub.zfill(9)
    return f"G{sub_suffix}"[:15]


def google_login(
    db: Session,
    token: str | None = None,
    *,
    access_token: str | None = None,
) -> TokenResponse:
    """Authenticate or register a user seamlessly using Google OAuth 2.0.

    - Requires a verified Google email (`email_verified == True`).
    - If matching google_id or email exists: logs in and links Google metadata.
    - Otherwise: atomically creates a new Customer (auth_provider='GOOGLE')
      and an initial CASH InvestmentAccount.
    """
    if token:
        payload = verify_google_id_token(token)
    elif access_token:
        payload = verify_google_access_token(access_token)
    else:
        raise UnauthorizedException(
            "Thiếu mã xác thực từ Google.",
            code="INVALID_GOOGLE_TOKEN",
        )

    raw_email = payload.get("email")
    if not isinstance(raw_email, str) or not raw_email.strip():
        raise UnauthorizedException(
            "Google token không cung cấp địa chỉ email.",
            code="GOOGLE_EMAIL_MISSING",
        )

    email_verified = payload.get("email_verified")
    if email_verified not in (True, "true", "True"):
        raise UnauthorizedException(
            "Email Google chưa được xác minh.",
            code="GOOGLE_EMAIL_UNVERIFIED",
        )

    email = raw_email.strip().lower()
    raw_name = payload.get("name")
    full_name = (
        raw_name.strip() if isinstance(raw_name, str) and raw_name.strip() else email.split("@")[0]
    )
    avatar_url = _sanitize_avatar_url(payload.get("picture"))
    google_sub = str(payload.get("sub") or "").strip() or None
    phone_sentinel = _build_phone_sentinel(google_sub or secrets.token_hex(6))

    for attempt in range(ACCOUNT_NUMBER_ATTEMPTS):
        try:
            with db.begin():
                customer = _find_customer(db, email, google_sub or "")
                if customer is not None:
                    ensure_active(customer)
                    if google_sub and customer.google_id and customer.google_id != google_sub:
                        raise UnauthorizedException(
                            "Email này đã được liên kết với tài khoản Google khác.",
                            code="GOOGLE_ACCOUNT_MISMATCH",
                        )
                    if customer.auth_provider != "GOOGLE":
                        customer.auth_provider = "GOOGLE"
                    if google_sub and not customer.google_id:
                        customer.google_id = google_sub
                    if avatar_url and not customer.avatar_url:
                        customer.avatar_url = avatar_url
                    db.flush()
                    response = issue_tokens(customer)
                    return response

                actual_phone = phone_sentinel
                if attempt > 0 or db.scalar(
                    select(Customer).where(Customer.phone_number == actual_phone)
                ):
                    actual_phone = f"G{secrets.token_hex(6).upper()}"[:15]

                new_customer = Customer(
                    full_name=full_name[:100],
                    email=email,
                    phone_number=actual_phone,
                    password_hash=GOOGLE_OAUTH_PASSWORD_SENTINEL,
                    avatar_url=avatar_url,
                    role="CUSTOMER",
                    status="ACTIVE",
                    auth_provider="GOOGLE",
                    google_id=google_sub,
                )
                db.add(new_customer)
                db.flush()

                db.add(
                    InvestmentAccount(
                        customer_id=new_customer.customer_id,
                        account_number=generate_account_number(),
                        account_type="CASH",
                        status="ACTIVE",
                        cash_balance=INITIAL_CASH,
                        blocked_balance=Decimal("0.00"),
                        total_asset_value=INITIAL_CASH,
                        margin_limit=Decimal("0.00"),
                    )
                )
                db.flush()
                response = issue_tokens(new_customer)
            return response
        except IntegrityError as exc:
            constraint = getattr(getattr(exc.orig, "diag", None), "constraint_name", None)
            if constraint in ("uq_customers_email", "uq_customers_google_id"):
                with db.begin():
                    existing = _find_customer(db, email, google_sub or "")
                    if existing is not None:
                        ensure_active(existing)
                        return issue_tokens(existing)
            if constraint not in ("uq_accounts_number", "uq_customers_phone"):
                raise

    raise AppException(503, "DATABASE_UNAVAILABLE", "Chưa thể tạo tài khoản, vui lòng thử lại.")
