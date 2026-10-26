"""TV4 checkpoint 1: token/validation/health tests independent of PostgreSQL."""

from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from pydantic import ValidationError
from sqlalchemy.exc import OperationalError

from app.api.deps import get_db
from app.core.config import settings
from app.core.errors import UnauthorizedException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.main import app
from app.schemas.auth import RegisterRequest


def test_jwt_lifetimes_and_types():
    access = decode_access_token(create_access_token({"sub": "1"}))
    refresh = decode_token(create_refresh_token({"sub": "1"}), "refresh")
    assert access["exp"] - access["iat"] == settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    assert refresh["exp"] - refresh["iat"] == settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400
    with pytest.raises(UnauthorizedException):
        decode_access_token(create_refresh_token({"sub": "1"}))
    with pytest.raises(UnauthorizedException):
        decode_token(create_access_token({"sub": "1"}), "refresh")


@pytest.mark.parametrize("claim", ["sub", "exp", "iat", "type"])
def test_reject_missing_required_claim(claim):
    payload = jwt.get_unverified_claims(create_access_token({"sub": "1"}))
    del payload[claim]
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    with pytest.raises(UnauthorizedException):
        decode_access_token(token)


@pytest.mark.parametrize("sub", [None, 1, [], "abc", "-1", "0", "９", "9" * 40])
def test_reject_malformed_subject(sub):
    with pytest.raises(UnauthorizedException):
        decode_access_token(create_access_token({"sub": sub}))


def test_reject_expired_and_tampered_tokens():
    token = create_access_token({"sub": "1"}, timedelta(seconds=-10))
    with pytest.raises(UnauthorizedException) as error:
        decode_access_token(token)
    assert error.value.detail["error"]["code"] == "TOKEN_EXPIRED"
    forged = jwt.encode(
        {"sub": "1", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        "different-key",
        algorithm=settings.ALGORITHM,
    )
    with pytest.raises(UnauthorizedException) as error:
        decode_access_token(forged)
    assert error.value.detail["error"]["code"] == "UNAUTHORIZED"


@pytest.mark.parametrize("claim", ["iat", "exp"])
@pytest.mark.parametrize("value", [None, [], {}, "not-a-date", True])
def test_reject_malformed_timestamps(claim, value):
    payload = jwt.get_unverified_claims(create_access_token({"sub": "1"}))
    payload[claim] = value
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    with pytest.raises(UnauthorizedException):
        decode_access_token(token)


def test_bcrypt_never_silently_truncates():
    password = "x" * 72
    hashed = get_password_hash(password)
    assert hashed != password and verify_password(password, hashed)
    assert not verify_password(password + "extra", hashed)
    assert not verify_password("wrong-password", hashed)
    with pytest.raises(ValueError):
        get_password_hash("á" * 37)


@pytest.mark.parametrize(
    "changes",
    [
        {"email": "not-an-email"},
        {"full_name": "   "},
        {"phone_number": "0123456789"},
        {"phone_number": "09012345678"},
        {"password": "short"},
        {"password": "á" * 37},
        {"role": "ADMIN"},
        {"initial_cash_balance": "99999999999.00"},
    ],
)
def test_registration_schema_rejects_invalid_input(changes):
    payload = dict(
        full_name=" Demo ",
        email=" DEMO@EXAMPLE.COM ",
        phone_number="0901234567",
        password="Matkhau@123",
    )
    with pytest.raises(ValidationError):
        RegisterRequest(**(payload | changes))


def test_registration_schema_normalizes_email_and_name():
    request = RegisterRequest(
        full_name=" Demo ",
        email=" DEMO@EXAMPLE.COM ",
        phone_number="0901234567",
        password="Matkhau@123",
    )
    assert request.email == "demo@example.com"
    assert request.full_name == "Demo"


def test_health_survives_db_failure_without_leaking_credentials():
    class BrokenDB:
        def execute(self, _):
            raise OperationalError("SELECT 1", {}, Exception("postgres://user:secret@host/db"))

    def broken_db():
        yield BrokenDB()

    app.dependency_overrides[get_db] = broken_db
    try:
        with TestClient(app) as client:
            assert client.get("/health/live").status_code == 200
            response = client.get("/health/ready")
            assert response.status_code == 503
            assert response.json()["error"]["code"] == "DATABASE_UNAVAILABLE"
            assert "secret" not in response.text
    finally:
        app.dependency_overrides.pop(get_db, None)


def test_http_validation_error_does_not_echo_password_or_token():
    def unused_db():
        yield None

    app.dependency_overrides[get_db] = unused_db
    try:
        with TestClient(app) as client:
            password = "DO-NOT-ECHO-THIS-PASSWORD"
            response = client.post("/api/auth/register", json={"password": password})
            assert response.status_code == 422
            assert response.json()["error"]["code"] == "VALIDATION_ERROR"
            assert password not in response.text
            assert client.get("/api/accounts").json()["error"]["code"] == "UNAUTHORIZED"
    finally:
        app.dependency_overrides.pop(get_db, None)
