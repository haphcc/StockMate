"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication endpoints for customer login, admin login, and user profile.
"""

from fastapi import APIRouter

from app.api.deps import CurrentUserDep, DbDep
from app.schemas.auth import (
    ChangePasswordRequest,
    GoogleLoginRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UpdateProfileRequest,
    UserResponse,
)
from app.services import auth_service, google_auth_service

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(request: RegisterRequest, db: DbDep) -> TokenResponse:
    return auth_service.register(db, request)


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: DbDep) -> TokenResponse:
    return auth_service.login(db, request)


@router.post("/google", response_model=TokenResponse)
def google_login(request: GoogleLoginRequest, db: DbDep) -> TokenResponse:
    """Seamless Google Sign-In and Sign-Up via Google ID Token or Access Token."""
    return google_auth_service.google_login(
        db,
        request.id_token,
        access_token=request.access_token,
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(request: RefreshRequest, db: DbDep) -> TokenResponse:
    return auth_service.refresh(db, request.refresh_token)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: CurrentUserDep) -> UserResponse:
    """Return currently authenticated user information."""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse)
def update_me(
    request: UpdateProfileRequest,
    current_user: CurrentUserDep,
    db: DbDep,
) -> UserResponse:
    """Update currently authenticated user information."""
    updated = auth_service.update_profile(db, current_user, request)
    return UserResponse.model_validate(updated)


@router.put("/password")
def change_password(
    request: ChangePasswordRequest,
    current_user: CurrentUserDep,
    db: DbDep,
) -> dict[str, str]:
    """Change password for currently authenticated user."""
    auth_service.change_password(db, current_user, request)
    return {"message": "Đổi mật khẩu thành công."}
