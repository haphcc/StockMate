"""Owner: TV4 - LB / TV1 - Phuoc.

Common API dependencies for database sessions and authentication/authorization.
"""

from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.errors import ForbiddenException, UnauthorizedException
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.customer import Customer

security_bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security_bearer)],
    db: Annotated[Session, Depends(get_db)],
) -> Customer:
    """Validate JWT access token and return current authenticated customer."""
    if credentials is None or not credentials.credentials:
        raise UnauthorizedException(
            message="Thiếu access token xác thực.",
            code="UNAUTHORIZED",
        )

    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None:
        raise UnauthorizedException(
            message="Access token không hợp lệ hoặc đã hết hạn.",
            code="TOKEN_EXPIRED",
        )

    sub = payload.get("sub")
    if not sub:
        raise UnauthorizedException(
            message="Token không chứa thông tin định danh.",
            code="INVALID_CREDENTIALS",
        )

    try:
        customer_id = int(sub)
    except ValueError:
        raise UnauthorizedException(
            message="Token không hợp lệ.",
            code="INVALID_CREDENTIALS",
        )

    customer = db.query(Customer).filter(Customer.customer_id == customer_id).first()
    if customer is None:
        raise UnauthorizedException(
            message="Người dùng không tồn tại.",
            code="UNAUTHORIZED",
        )

    if customer.status == "LOCKED":
        raise ForbiddenException(
            message="Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.",
            code="ACCOUNT_LOCKED",
        )
    if customer.status == "CLOSED":
        raise ForbiddenException(
            message="Tài khoản này đã bị đóng.",
            code="ACCOUNT_CLOSED",
        )

    return customer


def get_current_admin(
    current_user: Annotated[Customer, Depends(get_current_user)],
) -> Customer:
    """Validate that current authenticated user has ADMIN role."""
    if current_user.role != "ADMIN":
        raise ForbiddenException(
            message="Yêu cầu quyền Quản trị viên (Admin) để thực hiện thao tác này.",
            code="FORBIDDEN",
        )
    return current_user


# Type aliases for dependency injection in endpoints
DbDep = Annotated[Session, Depends(get_db)]
CurrentUserDep = Annotated[Customer, Depends(get_current_user)]
CurrentAdminDep = Annotated[Customer, Depends(get_current_admin)]
