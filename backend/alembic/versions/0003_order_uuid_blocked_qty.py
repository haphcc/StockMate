"""Add client_order_id to stock_orders and blocked_quantity to portfolios.

Revision ID: 0003_order_uuid_blocked_qty
Revises: 0002_add_admin_role
Create Date: 2026-10-26 13:25:00
Owner: TV1 - Phuoc
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003_order_uuid_blocked_qty"
down_revision: Union[str, None] = "0002_add_admin_role"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # 1. Add client_order_id to stock_orders if missing
    has_client_order_id = bind.execute(
        sa.text(
            """
            SELECT COUNT(*) FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = 'stock_orders' 
              AND column_name = 'client_order_id'
            """
        )
    ).scalar()

    if not has_client_order_id:
        op.add_column(
            "stock_orders",
            sa.Column(
                "client_order_id",
                sa.Uuid(),
                server_default=sa.text("gen_random_uuid()"),
                nullable=False,
            ),
        )

    # 2. Add blocked_quantity to portfolios if missing
    has_blocked_qty = bind.execute(
        sa.text(
            """
            SELECT COUNT(*) FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = 'portfolios' 
              AND column_name = 'blocked_quantity'
            """
        )
    ).scalar()

    if not has_blocked_qty:
        op.add_column(
            "portfolios",
            sa.Column(
                "blocked_quantity",
                sa.Integer(),
                server_default="0",
                nullable=False,
            ),
        )


def downgrade() -> None:
    op.drop_column("stock_orders", "client_order_id")
    op.drop_column("portfolios", "blocked_quantity")
