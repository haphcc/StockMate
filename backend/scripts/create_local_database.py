"""Create the configured local StockMate database if it does not exist."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from app.core.config import settings


def main() -> None:
    """Create ``POSTGRES_DB`` through the configured PostgreSQL server."""
    database_url = make_url(settings.DATABASE_URL)
    database_name = settings.POSTGRES_DB
    admin_engine = create_engine(
        database_url.set(database="postgres"),
        isolation_level="AUTOCOMMIT",
    )

    with admin_engine.connect() as connection:
        exists = connection.execute(
            text("SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = :name)"),
            {"name": database_name},
        ).scalar()
        if not exists:
            quoted_name = database_name.replace('"', '""')
            connection.execute(text(f'CREATE DATABASE "{quoted_name}"'))
            print(f"Created database: {database_name}")
        else:
            print(f"Database already exists: {database_name}")


if __name__ == "__main__":
    main()
