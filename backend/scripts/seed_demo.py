"""Seed a migrated, empty DEV database. Never resets existing application data."""

from pathlib import Path

import bcrypt
from sqlalchemy import text

from app.db.session import get_engine

SQL_ROOT = Path(__file__).resolve().parents[2] / "data" / "postgres"
SEEDS = (
    "03_seed_stocks.sql",
    "04_seed_customers.sql",
    "05_seed_trading.sql",
    "06_seed_price_history.sql",
    "07_seed_notifications.sql",
)
TABLES = (
    "customers",
    "investment_accounts",
    "stocks",
    "portfolios",
    "stock_orders",
    "transactions",
    "watchlists",
    "stock_price_history",
    "notifications",
)


def main() -> None:
    with get_engine().begin() as connection:
        # Serialize concurrent seed attempts; refuse even partially populated datasets.
        connection.execute(text("SELECT pg_advisory_xact_lock(20261025)"))
        for name in TABLES:
            if connection.execute(text(f"SELECT EXISTS(SELECT 1 FROM {name})")).scalar():
                raise SystemExit("Seed refused: database contains data. Use a new DEV database.")
        for name in SEEDS:
            connection.exec_driver_sql((SQL_ROOT / name).read_text(encoding="utf-8"))
        password_hash = bcrypt.hashpw(b"Matkhau@123", bcrypt.gensalt()).decode("ascii")
        connection.execute(
            text("UPDATE customers SET password_hash = :password_hash"),
            {"password_hash": password_hash},
        )
    print("Demo seeded once; email: an.nguyen@gmail.com; password: Matkhau@123")
    print("Auth endpoints remain 501 until TV4 implements them.")


if __name__ == "__main__":
    main()
