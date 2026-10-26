"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication request and response schemas.
"""

from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    """User login credential payload."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Authenticated user profile response."""

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
    refresh_token: str = ""
    token_type: str = "bearer"
    expires_in: int = 86400
    user: UserResponse
