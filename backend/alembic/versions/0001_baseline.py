"""Snapshot of the reviewed prototype schema, not a completed trading engine.

Owner: TV1 - Phuoc. Corrections belong in 0002+, never edit this snapshot after use.
"""

from pathlib import Path

from sqlalchemy import inspect

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None

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
SNAPSHOTS = Path(__file__).resolve().parents[1] / "sql"


def upgrade() -> None:
    connection = op.get_bind()
    existing = set(inspect(connection).get_table_names()).intersection(TABLES)
    if existing:
        raise RuntimeError(
            "Baseline requires an empty application schema; existing tables: "
            + ", ".join(sorted(existing))
            + ". Use a separate DEV database; do not reset an existing database."
        )
    for name in ("0001_schema.sql", "0001_functions.sql", "0001_views.sql"):
        connection.exec_driver_sql((SNAPSHOTS / name).read_text(encoding="utf-8"))


def downgrade() -> None:
    for name in (
        "v_watchlist_detail",
        "v_transaction_history",
        "v_order_book",
        "v_account_summary",
        "v_portfolio_detail",
        "v_market_board",
    ):
        op.execute(f"DROP VIEW {name}")
    for name in reversed(TABLES):
        op.drop_table(name)
    for signature in (
        "sp_update_market_price(VARCHAR, NUMERIC)",
        "sp_settle_pending_shares()",
    ):
        op.execute(f"DROP PROCEDURE {signature}")
    for signature in (
        "fn_apply_transaction()",
        "fn_reprice_portfolios()",
        "fn_set_price_limits()",
        "fn_recalc_account_asset(BIGINT)",
        "fn_price_band(VARCHAR)",
        "fn_price_tick(VARCHAR, NUMERIC)",
    ):
        op.execute(f"DROP FUNCTION {signature}")
