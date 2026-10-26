"""TV4 CP1 against real PostgreSQL migrations, transactions and uniqueness.

TEST_DATABASE_URL points to a PostgreSQL server where the test role can CREATE DATABASE.
This suite creates/drops ONLY its own randomly named stockmate_cp1_test_* database.
"""

import os
import subprocess
import sys
import uuid
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
from pathlib import Path
from threading import Barrier

import pytest
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event, func, select, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from alembic import command
from app.api.deps import get_db
from app.core.security import create_access_token
from app.main import app
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.services import auth_service

pytestmark = pytest.mark.integration
BACKEND_DIR = Path(__file__).resolve().parents[2]
PASSWORD = "Matkhau@123"


@pytest.fixture(scope="module")
def pg_engine():
    base_url = os.environ.get("TEST_DATABASE_URL")
    if not base_url:
        pytest.skip("Set TEST_DATABASE_URL to run against disposable PostgreSQL")
    database = "stockmate_cp1_test_" + uuid.uuid4().hex
    url = make_url(base_url)
    assert url.drivername == "postgresql+psycopg"
    admin = create_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    engine = create_engine(url.set(database=database))
    old_url = os.environ.get("DATABASE_URL")
    try:
        with admin.connect() as conn:
            conn.execute(text(f'CREATE DATABASE "{database}"'))
        os.environ["DATABASE_URL"] = engine.url.render_as_string(hide_password=False)
        config = Config(str(BACKEND_DIR / "alembic.ini"))
        config.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
        command.upgrade(config, "head")
        command.upgrade(config, "head")  # A second migration must be a no-op.
        yield engine
    finally:
        if old_url is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = old_url
        engine.dispose()
        with admin.connect() as conn:
            conn.execute(text(f'DROP DATABASE IF EXISTS "{database}" WITH (FORCE)'))
        admin.dispose()


@pytest.fixture()
def client(pg_engine):
    with pg_engine.begin() as conn:
        conn.execute(text("TRUNCATE customers RESTART IDENTITY CASCADE"))

    def test_db():
        with Session(pg_engine) as db:
            yield db

    app.dependency_overrides[get_db] = test_db
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.pop(get_db, None)


def payload(email="demo@example.com", phone="0901234567"):
    return dict(full_name=" Demo User ", email=email, phone_number=phone, password=PASSWORD)


def register(client, **kwargs):
    response = client.post("/api/auth/register", json=payload(**kwargs))
    assert response.status_code == 201, response.text
    return response.json()


def headers(tokens):
    return {"Authorization": "Bearer " + tokens["access_token"]}


def counts(engine):
    with Session(engine) as db:
        return (
            db.scalar(select(func.count()).select_from(Customer)),
            db.scalar(select(func.count()).select_from(InvestmentAccount)),
        )


def test_register_login_refresh_me_accounts(client, pg_engine):
    tokens = register(client, email=" DEMO@EXAMPLE.COM ")
    assert tokens["user"]["role"] == "CUSTOMER"
    assert tokens["user"]["full_name"] == "Demo User"
    assert tokens["user"]["email"] == "demo@example.com"
    assert tokens["refresh_token"] and tokens["expires_in"] == 900
    assert "password_hash" not in tokens["user"]
    user_id = tokens["user"]["customer_id"]
    assert client.get("/api/auth/me", headers=headers(tokens)).json() == tokens["user"]
    accounts = client.get("/api/accounts", headers=headers(tokens))
    assert accounts.status_code == 200
    assert len(accounts.json()) == 1
    assert accounts.json()[0]["account_type"] == "CASH"
    with Session(pg_engine) as db:
        account = db.scalar(select(InvestmentAccount))
        customer = db.get(Customer, user_id)
        assert customer.password_hash.startswith("$2")
        assert account.cash_balance == account.total_asset_value == Decimal("1000000000.00")
        assert account.blocked_balance == account.margin_limit == Decimal("0.00")
        assert account.customer_id == user_id
        account.cash_balance = Decimal("123.45")
        db.commit()
    for _ in range(2):
        login = client.post(
            "/api/auth/login", json={"email": " DEMO@EXAMPLE.COM ", "password": PASSWORD}
        )
        assert login.status_code == 200
        refresh = client.post(
            "/api/auth/refresh", json={"refresh_token": login.json()["refresh_token"]}
        )
        assert refresh.status_code == 200
        assert (
            client.get("/api/accounts", headers=headers(refresh.json())).json() == accounts.json()
        )
    assert counts(pg_engine) == (1, 1)
    with Session(pg_engine) as db:
        assert db.scalar(select(InvestmentAccount.cash_balance)) == Decimal("123.45")


@pytest.mark.parametrize(
    "email,phone,code",
    [
        (" DEMO@EXAMPLE.COM ", "0907654321", "DUPLICATE_EMAIL"),
        ("other@example.com", "0901234567", "DUPLICATE_PHONE"),
    ],
)
def test_duplicate_register_does_not_grant_extra_cash(client, pg_engine, email, phone, code):
    register(client)
    response = client.post("/api/auth/register", json=payload(email, phone))
    assert response.status_code == 409
    assert response.json()["error"]["code"] == code
    assert counts(pg_engine) == (1, 1)


@pytest.mark.parametrize("field", ["full_name", "email", "phone_number", "password"])
def test_missing_required_fields_never_write(client, pg_engine, field):
    data = payload()
    del data[field]
    assert client.post("/api/auth/register", json=data).status_code == 422
    assert counts(pg_engine) == (0, 0)


def test_ownership_and_account_order(client, pg_engine):
    first = register(client)
    second = register(client, email="other@example.com", phone="0907654321")
    with Session(pg_engine) as db:
        db.add(
            InvestmentAccount(
                customer_id=first["user"]["customer_id"],
                account_number="EXTRA-CASH",
                account_type="CASH",
                status="ACTIVE",
            )
        )
        db.commit()
    first_accounts = client.get("/api/accounts?customer_id=2", headers=headers(first)).json()
    second_accounts = client.get("/api/accounts?customer_id=1", headers=headers(second)).json()
    assert len(first_accounts) == 2 and len(second_accounts) == 1
    ids = [a["account_id"] for a in first_accounts]
    assert ids == sorted(ids)
    assert not set(ids) & {a["account_id"] for a in second_accounts}


def test_token_type_expiry_and_bad_credentials(client):
    tokens = register(client)
    assert (
        client.get(
            "/api/auth/me",
            headers={
                "Authorization": "Bearer " + tokens["refresh_token"],
            },
        ).status_code
        == 401
    )
    assert (
        client.post(
            "/api/auth/refresh",
            json={
                "refresh_token": tokens["access_token"],
            },
        ).status_code
        == 401
    )
    wrong = client.post("/api/auth/login", json={"email": "demo@example.com", "password": "wrong"})
    unknown = client.post(
        "/api/auth/login", json={"email": "unknown@example.com", "password": "wrong"}
    )
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()
    assert client.post("/api/auth/refresh", json={"refresh_token": "invalid"}).status_code == 401


@pytest.mark.parametrize("status", ["PENDING", "LOCKED", "CLOSED"])
def test_inactive_customer_cannot_login_refresh_or_use_token(client, pg_engine, status):
    tokens = register(client)
    with Session(pg_engine) as db:
        db.get(Customer, tokens["user"]["customer_id"]).status = status
        db.commit()
    responses = [
        client.post("/api/auth/login", json={"email": "demo@example.com", "password": PASSWORD}),
        client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]}),
        client.get("/api/auth/me", headers=headers(tokens)),
        client.get("/api/accounts", headers=headers(tokens)),
    ]
    for response in responses:
        assert response.status_code == 403
        assert response.json()["error"]["code"] == "ACCOUNT_INACTIVE"


def test_deleted_customer_and_live_role_checks(client, pg_engine):
    tokens = register(client)
    forged_role = create_access_token({"sub": str(tokens["user"]["customer_id"]), "role": "ADMIN"})
    assert (
        client.get(
            "/api/admin/dashboard",
            headers={
                "Authorization": "Bearer " + forged_role,
            },
        ).status_code
        == 403
    )
    with Session(pg_engine) as db:
        db.delete(db.get(Customer, tokens["user"]["customer_id"]))
        db.commit()
    assert client.get("/api/auth/me", headers=headers(tokens)).status_code == 401
    assert (
        client.post(
            "/api/auth/refresh",
            json={
                "refresh_token": tokens["refresh_token"],
            },
        ).status_code
        == 401
    )


def test_failure_after_customer_insert_rolls_back_everything(client, pg_engine, monkeypatch):
    def fail_number():
        raise RuntimeError("injected failure after customer insert")

    monkeypatch.setattr(auth_service, "generate_account_number", fail_number)
    with pytest.raises(RuntimeError, match="injected failure"):
        client.post("/api/auth/register", json=payload())
    assert counts(pg_engine) == (0, 0)


def test_account_number_collision_retries_transaction(client, pg_engine, monkeypatch):
    register(client)
    with Session(pg_engine) as db:
        number = db.scalar(select(InvestmentAccount.account_number))
    numbers = iter([number, "068C0000000000000001"])
    monkeypatch.setattr(auth_service, "generate_account_number", lambda: next(numbers))
    register(client, email="other@example.com", phone="0907654321")
    assert counts(pg_engine) == (2, 2)


def test_account_number_retry_limit_rolls_back(client, pg_engine, monkeypatch):
    register(client)
    with Session(pg_engine) as db:
        number = db.scalar(select(InvestmentAccount.account_number))
    monkeypatch.setattr(auth_service, "generate_account_number", lambda: number)
    response = client.post("/api/auth/register", json=payload("other@example.com", "0907654321"))
    assert response.status_code == 503
    assert counts(pg_engine) == (1, 1)


@pytest.mark.parametrize("duplicate", ["email", "phone"])
def test_concurrent_registration_is_atomic(client, pg_engine, duplicate):
    barrier = Barrier(2, timeout=15)

    def synchronize_customer_insert(session, *_):
        if any(isinstance(obj, Customer) for obj in session.new):
            barrier.wait()

    event.listen(Session, "before_flush", synchronize_customer_insert)
    first = payload()
    second = payload("other@example.com", "0907654321")
    if duplicate == "email":
        second["email"] = first["email"].upper()
    else:
        second["phone_number"] = first["phone_number"]
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            responses = list(
                pool.map(lambda data: client.post("/api/auth/register", json=data), [first, second])
            )
    finally:
        event.remove(Session, "before_flush", synchronize_customer_insert)
    assert sorted(response.status_code for response in responses) == [201, 409]
    conflict = next(response for response in responses if response.status_code == 409)
    assert conflict.json()["error"]["code"] == "DUPLICATE_" + duplicate.upper()
    assert counts(pg_engine) == (1, 1)
    with Session(pg_engine) as db:
        assert db.scalar(select(func.sum(InvestmentAccount.cash_balance))) == Decimal(
            "1000000000.00"
        )


def test_health_and_openapi(client):
    assert client.get("/health/live").status_code == 200
    assert client.get("/health/ready").status_code == 200
    schema = client.get("/api/openapi.json").json()
    assert {
        "/api/auth/register",
        "/api/auth/login",
        "/api/auth/refresh",
        "/api/auth/me",
        "/api/accounts",
    } <= schema["paths"].keys()
    error_schema = schema["paths"]["/api/auth/register"]["post"]["responses"]["422"]
    assert error_schema["content"]["application/json"]["schema"]["$ref"].endswith("/ErrorResponse")


def test_seed_demo_can_bootstrap_and_refuses_to_seed_again(client, pg_engine):
    env = os.environ | {"DATABASE_URL": pg_engine.url.render_as_string(hide_password=False)}
    result = subprocess.run(
        [sys.executable, "scripts/seed_demo.py"],
        cwd=BACKEND_DIR,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    assert result.returncode == 0, result.stdout
    assert counts(pg_engine) == (10, 13)
    with Session(pg_engine) as db:
        cash = db.scalar(select(func.sum(InvestmentAccount.cash_balance)))
    second = subprocess.run(
        [sys.executable, "scripts/seed_demo.py"],
        cwd=BACKEND_DIR,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    assert second.returncode == 0 and "REJECTED" in second.stdout
    assert counts(pg_engine) == (10, 13)
    with Session(pg_engine) as db:
        assert db.scalar(select(func.sum(InvestmentAccount.cash_balance))) == cash
    login = client.post(
        "/api/auth/login", json={"email": "an.nguyen@gmail.com", "password": PASSWORD}
    )
    assert login.status_code == 200 and login.json()["user"]["role"] == "ADMIN"
