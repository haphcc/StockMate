"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication endpoints for customer login, admin login, and user profile.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import CurrentUserDep, get_db
from app.core.config import settings
from app.core.errors import UnauthorizedException
from app.core.security import create_access_token, verify_password
from app.models.customer import Customer
from app.schemas.auth import LoginRequest, TokenResponse, UserResponse

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    """Authenticate customer or admin user and return JWT access token."""
    customer = db.query(Customer).filter(Customer.email == request.email).first()
    if customer is None or not verify_password(request.password, customer.password_hash):
        raise UnauthorizedException(
            message="Email hoặc mật khẩu không chính xác.",
            code="INVALID_CREDENTIALS",
        )

    if customer.status == "LOCKED":
        raise UnauthorizedException(
            message="Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.",
            code="ACCOUNT_LOCKED",
        )
    if customer.status == "CLOSED":
        raise UnauthorizedException(
            message="Tài khoản này đã bị đóng.",
            code="ACCOUNT_CLOSED",
        )

    access_token = create_access_token(
        data={"sub": str(customer.customer_id), "role": customer.role, "email": customer.email}
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token="",
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse(
            customer_id=customer.customer_id,
            full_name=customer.full_name,
            email=customer.email,
            phone_number=customer.phone_number,
            avatar_url=customer.avatar_url,
            status=customer.status,
            role=customer.role,
        ),
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: CurrentUserDep) -> UserResponse:
    """Return currently authenticated user information."""
    return UserResponse(
        customer_id=current_user.customer_id,
        full_name=current_user.full_name,
        email=current_user.email,
        phone_number=current_user.phone_number,
        avatar_url=current_user.avatar_url,
        status=current_user.status,
        role=current_user.role,
    )
