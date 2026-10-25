"""Only runs against a migrated/seeded disposable database ending in _test."""

import os
import subprocess
import sys
from pathlib import Path

import bcrypt
import pytest
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

TEST_URL = os.environ.get("TEST_DATABASE_URL")
pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        not TEST_URL, reason="Set TEST_DATABASE_URL to a disposable seeded *_test DB"
    ),
]


@pytest.fixture
def engine():
    assert make_url(TEST_URL).database.endswith("_test"), "Refusing a non-test database"
    instance = create_engine(TEST_URL)
    yield instance
    instance.dispose()


def test_baseline_tables_views_and_seed(engine):
    inspector = inspect(engine)
    assert set(inspector.get_table_names()) >= {
        "customers",
        "investment_accounts",
        "stocks",
        "portfolios",
        "stock_orders",
        "transactions",
        "watchlists",
        "stock_price_history",
        "notifications",
        "alembic_version",
    }
    assert len(inspector.get_view_names()) == 6
    with engine.connect() as connection:
        for name, expected in (("stocks", 83), ("customers", 10), ("investment_accounts", 13)):
            assert connection.execute(text(f"SELECT count(*) FROM {name}")).scalar_one() == expected
        hashed = connection.execute(
            text("SELECT password_hash FROM customers WHERE email = 'an.nguyen@gmail.com'")
        ).scalar_one()
        assert bcrypt.checkpw(b"Matkhau@123", hashed.encode("ascii"))


def test_seed_refuses_existing_data(engine):
    environment = {**os.environ, "DATABASE_URL": TEST_URL}
    result = subprocess.run(
        [sys.executable, "-m", "scripts.seed_demo"],
        cwd=Path(__file__).resolve().parents[2],
        env=environment,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0
    assert "Seed refused" in result.stderr
    with engine.connect() as connection:
        assert connection.execute(text("SELECT count(*) FROM stocks")).scalar_one() == 83


def test_migration_repeated_is_noop(engine):
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=Path(__file__).resolve().parents[2],
        env={**os.environ, "DATABASE_URL": TEST_URL},
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
