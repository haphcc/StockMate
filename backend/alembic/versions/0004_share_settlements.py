"""Add share_settlements ledger table for T+2 settlement tracking.

Revision ID: 0004_share_settlements
Revises: 0003_order_uuid_blocked_qty
Create Date: 2026-11-04 10:00:00
Owner: TV5 - Tuệ
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004_share_settlements"
down_revision: Union[str, None] = "0003_order_uuid_blocked_qty"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # Create share_settlements table if not exists
    has_table = bind.execute(
        sa.text(
            """
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'share_settlements'
            """
        )
    ).scalar()

    if not has_table:
        op.create_table(
            "share_settlements",
            sa.Column(
                "settlement_id",
                sa.BigInteger(),
                sa.Identity(always=True),
                primary_key=True,
                nullable=False,
            ),
            sa.Column(
                "transaction_id",
                sa.BigInteger(),
                sa.ForeignKey("transactions.transaction_id", ondelete="CASCADE"),
                nullable=False,
                unique=True,
            ),
            sa.Column(
                "account_id",
                sa.BigInteger(),
                sa.ForeignKey("investment_accounts.account_id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "stock_id",
                sa.BigInteger(),
                sa.ForeignKey("stocks.stock_id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("quantity", sa.Integer(), nullable=False),
            sa.Column("settlement_date", sa.Date(), nullable=False),
            sa.Column("status", sa.String(length=20), nullable=False, server_default="PENDING"),
            sa.Column("settled_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
        )
        op.create_index("idx_settlement_account", "share_settlements", ["account_id"])
        op.create_index("idx_settlement_date_status", "share_settlements", ["settlement_date", "status"])

        # Backfill existing BUY transactions
        bind.execute(
            sa.text(
                """
                INSERT INTO share_settlements (
                    transaction_id, account_id, stock_id, quantity, settlement_date, status, settled_at
                )
                SELECT
                    t.transaction_id,
                    t.account_id,
                    t.stock_id,
                    t.quantity,
                    COALESCE(t.settlement_date, CURRENT_DATE),
                    CASE WHEN COALESCE(t.settlement_date, CURRENT_DATE) <= CURRENT_DATE THEN 'SETTLED' ELSE 'PENDING' END,
                    CASE WHEN COALESCE(t.settlement_date, CURRENT_DATE) <= CURRENT_DATE THEN t.transaction_date ELSE NULL END
                FROM transactions t
                WHERE t.transaction_type = 'BUY'
                ON CONFLICT (transaction_id) DO NOTHING;
                """
            )
        )


def downgrade() -> None:
    op.drop_table("share_settlements")

