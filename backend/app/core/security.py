"""Owner: TV4 - LB / TV1 - Phuoc.

Authentication and security utilities for password hashing and JWT token processing.
"""

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError

from app.core.config import settings
from app.core.errors import UnauthorizedException


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a stored bcrypt hash."""
    try:
        if len(plain_password.encode("utf-8")) > 72:
            return False
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8"),
        )
    except (ValueError, TypeError):
        return False


def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt with salt rounds=12."""
    if len(password.encode("utf-8")) > 72:
        raise ValueError("Password must not exceed 72 UTF-8 bytes")
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def create_access_token(data: dict[str, Any], expires_delta: timedelta | None = None) -> str:
    """Generate a signed JWT access token."""
    return _create_token(
        data,
        "access",
        expires_delta
        if expires_delta is not None
        else timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(data: dict[str, Any]) -> str:
    """Create a refresh token that cannot authorize API requests."""
    return _create_token(data, "refresh", timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS))


def _create_token(data: dict[str, Any], token_type: str, lifetime: timedelta) -> str:
    now = datetime.now(timezone.utc)
    to_encode = {**data, "type": token_type, "iat": now, "exp": now + lifetime}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str, expected_type: str) -> dict[str, Any]:
    """Validate signature, required claims, token purpose and customer identity."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
            options={"require_exp": True, "require_iat": True, "require_sub": True},
        )
        sub = payload["sub"]
        if (
            payload.get("type") != expected_type
            or not isinstance(sub, str)
            or not sub.isascii()
            or not sub.isdecimal()
            or len(sub) > 19
            or not 0 < int(sub) <= 9223372036854775807
            or type(payload["iat"]) is not int
            or type(payload["exp"]) is not int
        ):
            raise JWTError("Invalid token claims")
        return payload
    except ExpiredSignatureError as exc:
        raise UnauthorizedException("Token đã hết hạn.", code="TOKEN_EXPIRED") from exc
    except (JWTError, TypeError, ValueError, OverflowError):
        raise UnauthorizedException("Token không hợp lệ.") from None


def decode_access_token(token: str) -> dict[str, Any]:
    """Decode an access token, rejecting refresh tokens."""
    return decode_token(token, "access")
