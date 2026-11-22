"""Real PostgreSQL fixtures for LB market/assets/trading handoff checks."""

import os
import uuid
from pathlib import Path

import pytest
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from alembic import command
from app.api.deps import get_db
from app.main import app
from app.models.stock import Stock


@pytest.fixture(scope="module")
def pg_engine():
    base_url = os.environ.get("TEST_DATABASE_URL")
    if not base_url:
        pytest.skip("Set TEST_DATABASE_URL for disposable PostgreSQL integration tests")
    database = "stockmate_lb_test_" + uuid.uuid4().hex
    url = make_url(base_url)
    assert url.drivername == "postgresql+psycopg"
    admin = create_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    engine = create_engine(url.set(database=database))
    old_url = os.environ.get("DATABASE_URL")
    try:
        with admin.connect() as conn:
            conn.execute(text(f'CREATE DATABASE "{database}"'))
        os.environ["DATABASE_URL"] = engine.url.render_as_string(hide_password=False)
        backend = Path(__file__).resolve().parents[2]
        config = Config(str(backend / "alembic.ini"))
        config.set_main_option("script_location", str(backend / "alembic"))
        command.upgrade(config, "head")
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
def cp_client(pg_engine):
    with pg_engine.begin() as conn:
        conn.execute(text("TRUNCATE customers, stocks RESTART IDENTITY CASCADE"))

    def test_db():
        with Session(pg_engine) as db:
            yield db

    app.dependency_overrides[get_db] = test_db
    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.fixture()
def cp_user(cp_client):
    result = cp_client.post(
        "/api/auth/register",
        json={
            "full_name": "LB Demo",
            "email": "lb@example.com",
            "phone_number": "0901234567",
            "password": "Matkhau@123",
        },
    )
    assert result.status_code == 201
    tokens = result.json()
    headers = {"Authorization": "Bearer " + tokens["access_token"]}
    account = cp_client.get("/api/accounts", headers=headers).json()[0]
    return tokens["user"]["customer_id"], account["account_id"], headers


@pytest.fixture()
def add_stock(pg_engine):
    def create(symbol="FPT", **values):
        with Session(pg_engine) as db:
            stock = Stock(
                **(
                    {
                        "stock_symbol": symbol,
                        "company_name": "Công ty " + symbol,
                        "exchange": "HOSE",
                        "current_price": "100000.00",
                        "reference_price": "100000.00",
                        "total_volume": 100,
                    }
                    | values
                )
            )
            db.add(stock)
            db.commit()
            return stock.stock_id

    return create
