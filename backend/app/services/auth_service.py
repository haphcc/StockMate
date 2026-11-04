"""Owner: TV4 - LB. Atomic registration and session issuance."""

import secrets
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import (
    AppException,
    ConflictException,
    ForbiddenException,
    UnauthorizedException,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse

INITIAL_CASH = Decimal("1000000000.00")
ACCOUNT_NUMBER_ATTEMPTS = 3


def ensure_active(customer: Customer) -> None:
    if customer.status != "ACTIVE":
        raise ForbiddenException(
            "Tài khoản chưa hoạt động hoặc đã bị khóa/đóng.", "ACCOUNT_INACTIVE"
        )


def issue_tokens(customer: Customer) -> TokenResponse:
    data = {"sub": str(customer.customer_id), "role": customer.role}
    return TokenResponse(
        access_token=create_access_token(data),
        refresh_token=create_refresh_token(data),
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(customer),
    )


def generate_account_number() -> str:
    return "068C" + secrets.token_hex(8).upper()


def register(db: Session, request: RegisterRequest) -> TokenResponse:
    password_hash = get_password_hash(request.password)
    for _ in range(ACCOUNT_NUMBER_ATTEMPTS):
        try:
            # A failed uniqueness check rolls back BOTH customer and initial funds.
            with db.begin():
                if db.scalar(select(Customer).where(func.lower(Customer.email) == request.email)):
                    raise ConflictException("Email đã được đăng ký.", "DUPLICATE_EMAIL")
                if db.scalar(select(Customer).where(Customer.phone_number == request.phone_number)):
                    raise ConflictException("Số điện thoại đã được đăng ký.", "DUPLICATE_PHONE")
                customer = Customer(
                    full_name=request.full_name,
                    email=str(request.email),
                    phone_number=request.phone_number,
                    password_hash=password_hash,
                    role="CUSTOMER",
                    status="ACTIVE",
                )
                db.add(customer)
                db.flush()
                db.add(
                    InvestmentAccount(
                        customer_id=customer.customer_id,
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
                response = issue_tokens(customer)
            return response
        except IntegrityError as exc:
            constraint = getattr(getattr(exc.orig, "diag", None), "constraint_name", None)
            if constraint == "uq_customers_email":
                raise ConflictException("Email đã được đăng ký.", "DUPLICATE_EMAIL") from exc
            if constraint == "uq_customers_phone":
                raise ConflictException(
                    "Số điện thoại đã được đăng ký.", "DUPLICATE_PHONE"
                ) from exc
            if constraint != "uq_accounts_number":
                raise
            # Retry a generated number collision in a NEW transaction, with a bound.
    raise AppException(503, "DATABASE_UNAVAILABLE", "Chưa thể tạo số tài khoản, vui lòng thử lại.")


def login(db: Session, request: LoginRequest) -> TokenResponse:
    customer = db.scalar(select(Customer).where(func.lower(Customer.email) == request.email))
    if customer is None or not verify_password(request.password, customer.password_hash):
        raise UnauthorizedException("Email hoặc mật khẩu không chính xác.", "INVALID_CREDENTIALS")
    ensure_active(customer)
    return issue_tokens(customer)


def refresh(db: Session, token: str) -> TokenResponse:
    payload = decode_token(token, "refresh")
    customer = db.get(Customer, int(payload["sub"]))
    if customer is None:
        raise UnauthorizedException()
    ensure_active(customer)
    return issue_tokens(customer)
