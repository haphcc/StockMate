"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication request and response schemas.
"""

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class LoginRequest(BaseModel):
    """User login credential payload."""

    email: EmailStr
    password: str

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value: object) -> object:
        return value.strip().lower() if isinstance(value, str) else value


class RegisterRequest(LoginRequest):
    """Public registration always creates a regular customer and a CASH account."""

    model_config = ConfigDict(extra="forbid")

    full_name: str = Field(min_length=1, max_length=100)
    email: EmailStr = Field(max_length=150)
    phone_number: str = Field(pattern=r"^0[35789][0-9]{8}$")
    password: str = Field(min_length=8, max_length=72)

    @field_validator("full_name", mode="before")
    @classmethod
    def trim_name(cls, value: object) -> object:
        return value.strip() if isinstance(value, str) else value

    @field_validator("password")
    @classmethod
    def validate_password_bytes(cls, value: str) -> str:
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Mật khẩu tối đa 72 byte UTF-8.")
        return value


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=1, max_length=4096)


class UserResponse(BaseModel):
    """Authenticated user profile response."""

    model_config = ConfigDict(from_attributes=True)

    customer_id: int
    full_name: str
    email: str
    phone_number: str
    avatar_url: str | None = None
    status: str
    role: str = "CUSTOMER"


class TokenResponse(BaseModel):
    """JWT token response containing access/refresh tokens and user details."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse
