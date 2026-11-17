"""Owner: TV4 - LB / TV1 - Phuoc.

Google OAuth 2.0 authentication service for StockMate.
Verifies Google ID Token, handles seamless account linking and new user provisioning.
"""

import logging
import secrets
from decimal import Decimal

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import AppException, ForbiddenException, UnauthorizedException
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


def verify_google_id_token(token: str) -> dict:
    """Verify Google ID token against Google's public certs and return token payload."""
    try:
        # If GOOGLE_CLIENT_ID is configured, verify audience; otherwise allow verification
        audience = settings.GOOGLE_CLIENT_ID if settings.GOOGLE_CLIENT_ID else None
        request = google_requests.Request()
        payload = id_token.verify_oauth2_token(token, request, audience=audience)
        return payload
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


def google_login(db: Session, token: str) -> TokenResponse:
    """
    Authenticate or register a user seamlessly using Google ID Token.

    - If email exists: Seamlessly log in and link account (auto-merge, no error).
    - If email does not exist: Provision new Customer with cash account and bonus.
    """
    payload = verify_google_id_token(token)

    email = payload.get("email")
    if not email:
        raise UnauthorizedException(
            "Google token không cung cấp địa chỉ email.",
            code="GOOGLE_EMAIL_MISSING",
        )

    email = email.strip().lower()
    full_name = payload.get("name") or email.split("@")[0]
    avatar_url = payload.get("picture")
    google_sub = str(payload.get("sub", ""))

    # 1. Check existing customer by email
    customer = db.scalar(select(Customer).where(func.lower(Customer.email) == email))

    if customer is not None:
        # Seamless account login / merge
        ensure_active(customer)
        if avatar_url and not customer.avatar_url:
            customer.avatar_url = avatar_url
            db.commit()
            db.refresh(customer)
        return issue_tokens(customer)

    # 2. Customer does not exist -> Register new user
    # Generate unique phone sentinel (length <= 15 for String(15) column)
    clean_sub = "".join(filter(str.isalnum, google_sub))
    sub_suffix = clean_sub[-9:] if len(clean_sub) >= 9 else clean_sub.zfill(9)
    phone_sentinel = f"G{sub_suffix}"[:15]

    for attempt in range(ACCOUNT_NUMBER_ATTEMPTS):
        try:
            with db.begin():
                # In case sentinel phone conflicts with another Google user
                actual_phone = phone_sentinel
                if attempt > 0 or db.scalar(select(Customer).where(Customer.phone_number == actual_phone)):
                    actual_phone = f"G{secrets.token_hex(6).upper()}"[:15]

                new_customer = Customer(
                    full_name=full_name[:100],
                    email=email,
                    phone_number=actual_phone,
                    password_hash="GOOGLE_OAUTH_ACCOUNT",  # Cannot be used for direct password login
                    avatar_url=avatar_url,
                    role="CUSTOMER",
                    status="ACTIVE",
                )
                db.add(new_customer)
                db.flush()

                # Create initial Cash Investment Account
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
            if constraint == "uq_customers_email":
                # Concurrently registered, fetch and return
                customer = db.scalar(select(Customer).where(func.lower(Customer.email) == email))
                if customer:
                    ensure_active(customer)
                    return issue_tokens(customer)
            if constraint != "uq_accounts_number" and constraint != "uq_customers_phone":
                raise

    raise AppException(503, "DATABASE_UNAVAILABLE", "Chưa thể tạo tài khoản, vui lòng thử lại.")
