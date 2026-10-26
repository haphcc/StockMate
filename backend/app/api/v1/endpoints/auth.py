"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication endpoints for customer login, admin login, and user profile.
"""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep, DbDep
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.services import auth_service

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(request: RegisterRequest, db: DbDep) -> TokenResponse:
    return auth_service.register(db, request)


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: DbDep) -> TokenResponse:
    return auth_service.login(db, request)


@router.post("/refresh", response_model=TokenResponse)
def refresh(request: RefreshRequest, db: DbDep) -> TokenResponse:
    return auth_service.refresh(db, request.refresh_token)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: CurrentUserDep) -> UserResponse:
    """Return currently authenticated user information."""
    return UserResponse.model_validate(current_user)
