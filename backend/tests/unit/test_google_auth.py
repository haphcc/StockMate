"""Unit tests for Google OAuth 2.0 authentication and Admin Google account visibility."""

import uuid
from contextlib import nullcontext
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.errors import ForbiddenException, UnauthorizedException
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

    # Empty access_token string should fail validation
    response = client.post("/api/auth/google", json={"access_token": ""})
    assert response.status_code == 422


def test_google_login_invalid_token():
    with patch(
        "app.services.google_auth_service.id_token.verify_oauth2_token",
        side_effect=ValueError("Token expired"),
    ):
        response = client.post("/api/auth/google", json={"id_token": "invalid.jwt.token"})
        assert response.status_code == 401
        data = response.json()
        assert data["error"]["code"] == "INVALID_GOOGLE_TOKEN"


def test_google_login_missing_email():
    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value={"sub": "12345", "email_verified": True},
    ):
        response = client.post("/api/auth/google", json={"id_token": "valid.token.no.email"})
        assert response.status_code == 401
        data = response.json()
        assert data["error"]["code"] == "GOOGLE_EMAIL_MISSING"


def test_google_login_unverified_email_rejected():
    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value={
            "sub": "12345",
            "email": "unverified@example.com",
            "email_verified": False,
        },
    ):
        response = client.post("/api/auth/google", json={"id_token": "valid.token.unverified"})
        assert response.status_code == 401
        data = response.json()
        assert data["error"]["code"] == "GOOGLE_EMAIL_UNVERIFIED"


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
        auth_provider="LOCAL",
        google_id=None,
    )

    class MockDb:
        def begin(self):
            return nullcontext()

        def scalar(self, stmt):
            # First lookup by google_id returns None, second by email returns mock_customer
            self._calls = getattr(self, "_calls", 0) + 1
            return None if self._calls == 1 else mock_customer

        def flush(self):
            pass

    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value={
            "sub": "google-user-123456",
            "email": "nguyenvana@gmail.com",
            "email_verified": True,
            "name": "Nguyễn Văn A",
            "picture": "https://lh3.googleusercontent.com/avatar",
        },
    ):
        token_resp = google_auth_service.google_login(MockDb(), "dummy.token")
        assert token_resp.access_token is not None
        assert token_resp.refresh_token is not None
        assert token_resp.user.email == "nguyenvana@gmail.com"
        assert token_resp.user.customer_id == 42
        assert token_resp.user.auth_provider == "GOOGLE"
        assert token_resp.user.has_password is True
        assert mock_customer.auth_provider == "GOOGLE"
        assert mock_customer.google_id == "google-user-123456"
        assert mock_customer.avatar_url == "https://lh3.googleusercontent.com/avatar"


def test_google_login_locked_user_rejected():
    mock_customer = Customer(
        customer_id=43,
        full_name="Locked User",
        email="locked@gmail.com",
        phone_number="0912345679",
        password_hash="GOOGLE_OAUTH_ACCOUNT",
        role="CUSTOMER",
        status="LOCKED",
        auth_provider="GOOGLE",
        google_id="google-locked-1",
    )

    class MockDb:
        def begin(self):
            return nullcontext()

        def scalar(self, stmt):
            return mock_customer

        def flush(self):
            pass

    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value={
            "sub": "google-locked-1",
            "email": "locked@gmail.com",
            "email_verified": True,
        },
    ):
        with pytest.raises(ForbiddenException):
            google_auth_service.google_login(MockDb(), "dummy.token")


def test_google_login_mismatch_google_id_rejected():
    mock_customer = Customer(
        customer_id=44,
        full_name="Existing Google User",
        email="linked@gmail.com",
        phone_number="0912345680",
        password_hash="GOOGLE_OAUTH_ACCOUNT",
        role="CUSTOMER",
        status="ACTIVE",
        auth_provider="GOOGLE",
        google_id="original-sub",
    )

    class MockDb:
        def begin(self):
            return nullcontext()

        def scalar(self, stmt):
            self._calls = getattr(self, "_calls", 0) + 1
            return None if self._calls == 1 else mock_customer

        def flush(self):
            pass

    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value={
            "sub": "different-sub",
            "email": "linked@gmail.com",
            "email_verified": True,
        },
    ):
        with pytest.raises(UnauthorizedException):
            google_auth_service.google_login(MockDb(), "dummy.token")


def test_google_access_token_web_fallback():
    mock_res = MagicMock()
    mock_res.status_code = 200
    mock_res.json.return_value = {
        "sub": "web-sub-777",
        "email": "webuser@gmail.com",
        "email_verified": True,
        "name": "Web Google User",
        "picture": "https://lh3.googleusercontent.com/web-avatar",
    }

    with (
        patch.object(google_auth_service.settings, "GOOGLE_CLIENT_ID", ""),
        patch("app.services.google_auth_service.requests.get", return_value=mock_res),
    ):
        payload = google_auth_service.verify_google_access_token("valid.web.access.token")
        assert payload["email"] == "webuser@gmail.com"
        assert payload["sub"] == "web-sub-777"


def test_google_new_user_end_to_end_and_admin_visibility():
    """End-to-end verification against live DB:
    - Creates new Google customer + CASH account without SQLAlchemy transaction crash
    - Persists auth_provider='GOOGLE' and google_id
    - Supports profile update, first-time password set, accounts, notifications, watchlist
    - Displays as Google account in Admin customer list, filter, detail, and update
    - Cleans up via Admin cascade delete
    """
    unique = uuid.uuid4().hex[:10]
    email = f"google_e2e_{unique}@gmail.com"
    google_sub = f"sub{unique}123456789"

    google_claims = {
        "sub": google_sub,
        "email": email,
        "email_verified": True,
        "name": "Google Investor E2E",
        "picture": "https://lh3.googleusercontent.com/e2e-avatar",
    }

    # 1. Sign up brand-new user with Google ID Token
    with patch(
        "app.services.google_auth_service.verify_google_id_token",
        return_value=google_claims,
    ):
        signup_res = client.post("/api/auth/google", json={"id_token": "valid.new.token"})
        assert signup_res.status_code == 200, signup_res.text
        signup_data = signup_res.json()
        assert signup_data["user"]["email"] == email
        assert signup_data["user"]["auth_provider"] == "GOOGLE"
        assert signup_data["user"]["has_password"] is False
        customer_id = signup_data["user"]["customer_id"]

        # 2. Repeated Google login returns same customer (no duplicate)
        repeat_res = client.post("/api/auth/google", json={"id_token": "valid.repeat.token"})
        assert repeat_res.status_code == 200, repeat_res.text
        assert repeat_res.json()["user"]["customer_id"] == customer_id

    user_headers = {"Authorization": f"Bearer {signup_data['access_token']}"}

    # Admin login for verification + guaranteed cleanup
    admin_login = client.post(
        "/api/auth/login",
        json={"email": "an.nguyen@gmail.com", "password": "Matkhau@123"},
    )
    assert admin_login.status_code == 200, admin_login.text
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    try:
        # 3. Verify normal app features work for Google user
        me_res = client.get("/api/auth/me", headers=user_headers)
        assert me_res.status_code == 200
        assert me_res.json()["auth_provider"] == "GOOGLE"
        assert me_res.json()["has_password"] is False

        accounts_res = client.get("/api/accounts", headers=user_headers)
        assert accounts_res.status_code == 200
        accounts = accounts_res.json()
        assert len(accounts) == 1
        assert accounts[0]["account_type"] == "CASH"
        assert accounts[0]["status"] == "ACTIVE"

        account_id = accounts[0]["account_id"]
        assets_res = client.get(f"/api/accounts/{account_id}/assets", headers=user_headers)
        assert assets_res.status_code == 200, assets_res.text
        assert Decimal(assets_res.json()["cash_balance"]) > 0

        # Refresh token works
        refresh_res = client.post(
            "/api/auth/refresh",
            json={"refresh_token": signup_data["refresh_token"]},
        )
        assert refresh_res.status_code == 200

        # Update name without being forced to enter phone number
        update_name_res = client.put(
            "/api/auth/me",
            headers=user_headers,
            json={"full_name": "Google Investor Updated"},
        )
        assert update_name_res.status_code == 200, update_name_res.text
        assert update_name_res.json()["full_name"] == "Google Investor Updated"

        # First-time password setup without old_password works for Google-only account
        set_pw_res = client.put(
            "/api/auth/password",
            headers=user_headers,
            json={"new_password": "NewGooglePass@123"},
        )
        assert set_pw_res.status_code == 200, set_pw_res.text

        me_after_pw = client.get("/api/auth/me", headers=user_headers)
        assert me_after_pw.json()["has_password"] is True
        assert me_after_pw.json()["auth_provider"] == "GOOGLE"

        # Now user can also log in via email + password
        pw_login_res = client.post(
            "/api/auth/login",
            json={"email": email, "password": "NewGooglePass@123"},
        )
        assert pw_login_res.status_code == 200, pw_login_res.text

        # Notifications & Watchlist accessible
        notif_res = client.get("/api/notifications", headers=user_headers)
        assert notif_res.status_code == 200
        wl_res = client.get("/api/watchlist", headers=user_headers)
        assert wl_res.status_code == 200

        # 4. Admin sees this customer clearly marked as GOOGLE
        admin_list = client.get(
            f"/api/admin/customers?q={email}&auth_provider=GOOGLE",
            headers=admin_headers,
        )
        assert admin_list.status_code == 200, admin_list.text
        items = admin_list.json()["items"]
        assert len(items) == 1
        assert items[0]["customer_id"] == customer_id
        assert items[0]["auth_provider"] == "GOOGLE"
        assert items[0]["google_id"] == google_sub

        # Filter by LOCAL must NOT return this Google user
        admin_local = client.get(
            f"/api/admin/customers?q={email}&auth_provider=LOCAL",
            headers=admin_headers,
        )
        assert admin_local.status_code == 200
        assert admin_local.json()["total"] == 0

        # Admin detail endpoint returns auth_provider='GOOGLE' and google_id
        admin_detail = client.get(
            f"/api/admin/customers/{customer_id}",
            headers=admin_headers,
        )
        assert admin_detail.status_code == 200, admin_detail.text
        detail_data = admin_detail.json()
        assert detail_data["auth_provider"] == "GOOGLE"
        assert detail_data["google_id"] == google_sub
        assert len(detail_data["accounts"]) == 1

        # Admin can update customer without touching placeholder phone
        admin_update = client.put(
            f"/api/admin/customers/{customer_id}",
            headers=admin_headers,
            json={"full_name": "Google Investor Admin Edited"},
        )
        assert admin_update.status_code == 200, admin_update.text
        assert admin_update.json()["auth_provider"] == "GOOGLE"
    finally:
        client.delete(f"/api/admin/customers/{customer_id}", headers=admin_headers)
