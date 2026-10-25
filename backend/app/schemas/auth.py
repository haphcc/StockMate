from typing import Annotated, Literal

from pydantic import EmailStr, Field

from app.schemas.common import ContractModel


class LoginRequest(ContractModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)


class RegisterRequest(LoginRequest):
    full_name: str = Field(min_length=1, max_length=100)
    phone_number: str = Field(pattern=r"^0[35789][0-9]{8}$")


class RefreshRequest(ContractModel):
    refresh_token: Annotated[str, Field(min_length=1)]


class UserResponse(ContractModel):
    customer_id: int
    full_name: str
    email: EmailStr
    phone_number: str
    avatar_url: str | None = None
    status: Literal["PENDING", "ACTIVE", "LOCKED", "CLOSED"]


class TokenResponse(ContractModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int = Field(gt=0, description="Access-token lifetime in seconds")
    user: UserResponse
