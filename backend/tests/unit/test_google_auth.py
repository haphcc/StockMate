"""Unit tests for Google OAuth 2.0 authentication."""

from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.core.errors import UnauthorizedException
from app.main import app
from app.models.customer import Customer
from app.services import google_auth_service

client = TestClient(app)


def test_google_login_schema_validation():
    # Empty payload should fail validation
    response = client.post("/api/auth/google", json={})
    assert response.status_code == 422

    # Empty token string should fail validation
    response = client.post("/api/auth/google", json={"id_token": ""})
    assert response.status_code == 422


def test_google_login_invalid_token():
    with patch("app.services.google_auth_service.id_token.verify_oauth2_token", side_effect=ValueError("Token expired")):
        response = client.post("/api/auth/google", json={"id_token": "invalid.jwt.token"})
        assert response.status_code == 401
        data = response.json()
        assert data["error"]["code"] == "INVALID_GOOGLE_TOKEN"


def test_google_login_missing_email():
    with patch("app.services.google_auth_service.verify_google_id_token", return_value={"sub": "12345"}):
        response = client.post("/api/auth/google", json={"id_token": "valid.token.no.email"})
        assert response.status_code == 401
        data = response.json()
        assert data["error"]["code"] == "GOOGLE_EMAIL_MISSING"


def test_google_login_existing_user_auto_link():
    """Seamless login when customer email already exists in DB."""
    mock_customer = Customer(
        customer_id=42,
        full_name="Nguyễn Văn A",
        email="nguyenvana@gmail.com",
        phone_number="0912345678",
        password_hash="somehash",
        avatar_url=None,
        role="CUSTOMER",
        status="ACTIVE",
    )

    class MockDb:
        def scalar(self, stmt):
            return mock_customer

        def commit(self):
            pass

        def refresh(self, obj):
            pass

    with patch("app.services.google_auth_service.verify_google_id_token", return_value={
        "sub": "google-user-123456",
        "email": "nguyenvana@gmail.com",
        "name": "Nguyễn Văn A",
        "picture": "https://lh3.googleusercontent.com/avatar",
    }):
        token_resp = google_auth_service.google_login(MockDb(), "dummy.token")
        assert token_resp.access_token is not None
        assert token_resp.refresh_token is not None
        assert token_resp.user.email == "nguyenvana@gmail.com"
        assert token_resp.user.customer_id == 42
        assert mock_customer.avatar_url == "https://lh3.googleusercontent.com/avatar"

