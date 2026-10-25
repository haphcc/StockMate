from sqlalchemy.exc import OperationalError

from app.api.v1.endpoints import health


def test_liveness_does_not_need_database(client):
    assert client.get("/health/live").json() == {"status": "ok"}


def test_readiness_failure_is_structured(client, monkeypatch):
    def unavailable():
        raise OperationalError("SELECT 1", {}, Exception("unavailable"))

    monkeypatch.setattr(health, "get_engine", unavailable)
    response = client.get("/health/ready")
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "DATABASE_UNAVAILABLE"


def test_stub_never_claims_success(client):
    response = client.post(
        "/api/auth/login",
        json={
            "email": "an.nguyen@gmail.com",
            "password": "Matkhau@123",
        },
    )
    assert response.status_code == 501
    assert response.json()["error"]["details"]["owner"] == "TV4 - LB"


def test_private_routes_require_authentication(client):
    assert client.get("/api/accounts").status_code == 401


def test_unverified_token_never_grants_access(client):
    response = client.get("/api/accounts", headers={"Authorization": "Bearer arbitrary"})
    assert response.status_code == 501


def test_validation_does_not_echo_password(client):
    response = client.post("/api/auth/register", json={"password": "secret"})
    assert response.status_code == 422
    assert "secret" not in response.text
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_openapi_declares_protected_routes_and_decimal_strings(client):
    schema = client.get("/openapi.json").json()
    assert schema["paths"]["/api/accounts"]["get"]["security"]
    order = schema["components"]["schemas"]["CreateOrderRequest"]
    assert order["properties"]["order_price"]["type"] == "string"
