"""Baseline migration for StockMate.

Revision ID: 0001_baseline
Revises: None
Create Date: 2026-10-26 10:00:00

Owner: TV1 - Phuoc
"""

from pathlib import Path
from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0001_baseline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

SQL_DIR = Path(__file__).resolve().parents[1] / "sql"


def check_existing_app_tables(connection) -> bool:
    """Check if application tables already exist in public schema."""
    result = connection.execute(
        sa.text(
            """
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name IN ('customers', 'investment_accounts', 'stocks')
            """
        )
    ).scalar()
    return bool(result and result > 0)


def execute_sql_file(connection, file_path: Path) -> None:
    """Execute raw SQL statements from a file safely."""
    sql_text = file_path.read_text(encoding="utf-8")
    try:
        import psycopg

        # Neu su dung psycopg, execute qua SQL wrapper de tranh parse '%' nham placeholder
        raw_conn = getattr(connection.connection, "driver_connection", connection.connection)
        with raw_conn.cursor() as cur:
            cur.execute(psycopg.sql.SQL(sql_text))
    except Exception:
        connection.exec_driver_sql(sql_text.replace("%", "%%"))


def upgrade() -> None:
    bind = op.get_bind()

    # Yeu cau DATABASE_WORKFLOW: chan chay baseline len DB da co bang app
    # Tru truong hop bang alembic_version da quan ly revision nay
    if check_existing_app_tables(bind):
        # Kiem tra xem co phai chay lai hay da co san du lieu
        # Neu bang da co san tu prototype ma chua qua Alembic thi bao loi an toan
        version_check = bind.execute(
            sa.text(
                """
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_name = 'alembic_version'
                )
                """
            )
        ).scalar()
        if not version_check:
            raise RuntimeError(
                "Database already contains application tables without Alembic management. "
                "Baseline migration requires a clean database or explicit baseline stamping "
                "to prevent data corruption."
            )

    # Thuc thi schema, functions & triggers, va views
    schema_file = SQL_DIR / "0001_schema.sql"
    functions_file = SQL_DIR / "0001_functions.sql"
    views_file = SQL_DIR / "0001_views.sql"

    if schema_file.exists():
        execute_sql_file(bind, schema_file)
    if functions_file.exists():
        execute_sql_file(bind, functions_file)
    if views_file.exists():
        execute_sql_file(bind, views_file)


def downgrade() -> None:
    bind = op.get_bind()

    # Drop views
    views = [
        "v_watchlist_detail",
        "v_transaction_history",
        "v_order_book",
        "v_account_summary",
        "v_portfolio_detail",
        "v_market_board",
    ]
    for v in views:
        bind.exec_driver_sql(f"DROP VIEW IF EXISTS {v} CASCADE;")

    # Drop triggers & functions
    bind.exec_driver_sql("DROP TRIGGER IF EXISTS trg_stocks_reprice ON stocks;")
    bind.exec_driver_sql("DROP TRIGGER IF EXISTS trg_transaction_apply ON transactions;")
    bind.exec_driver_sql("DROP TRIGGER IF EXISTS trg_stocks_price_limits ON stocks;")
    bind.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_update_market_price(VARCHAR, NUMERIC);")
    bind.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_settle_pending_shares();")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_reprice_portfolios();")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_apply_transaction();")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_recalc_account_asset(BIGINT);")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_set_price_limits();")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_price_band(VARCHAR);")
    bind.exec_driver_sql("DROP FUNCTION IF EXISTS fn_price_tick(VARCHAR, NUMERIC);")

    # Drop tables theo thu tu foreign key
    tables = [
        "notifications",
        "stock_price_history",
        "watchlists",
        "transactions",
        "stock_orders",
        "portfolios",
        "stocks",
        "investment_accounts",
        "customers",
    ]
    for t in tables:
        bind.exec_driver_sql(f"DROP TABLE IF EXISTS {t} CASCADE;")
