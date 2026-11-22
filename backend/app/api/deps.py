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
from app.services.auth_service import ensure_active

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
    customer_id = int(payload["sub"])

    customer = db.query(Customer).filter(Customer.customer_id == customer_id).first()
    if customer is None:
        raise UnauthorizedException(
            message="Người dùng không tồn tại.",
            code="UNAUTHORIZED",
        )

    ensure_active(customer)

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
