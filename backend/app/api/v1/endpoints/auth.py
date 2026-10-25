"""Owner: TV4 - LB. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from fastapi import APIRouter, Depends

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.schemas.common import ERROR_RESPONSES

router = APIRouter(tags=["auth"], responses=ERROR_RESPONSES)


@router.post("/auth/register", response_model=TokenResponse, status_code=201)
def register(
    payload: RegisterRequest,
):
    not_implemented("register", "TV4 - LB")


@router.post("/auth/login", response_model=TokenResponse, status_code=200)
def login(
    payload: LoginRequest,
):
    not_implemented("login", "TV4 - LB")


@router.post("/auth/refresh", response_model=TokenResponse, status_code=200)
def refresh(
    payload: RefreshRequest,
):
    not_implemented("refresh", "TV4 - LB")


@router.get(
    "/auth/me", response_model=UserResponse, status_code=200, dependencies=[Depends(require_user)]
)
def me():
    not_implemented("me", "TV4 - LB")
