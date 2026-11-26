"""Add auth_provider and google_id columns to customers table.

Revision ID: 0006_add_auth_provider_and_google_id
Revises: 0005_fix_trading_engine_trigger
Create Date: 2026-11-18 11:30:00
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0006_add_auth_provider_and_google_id"
down_revision: Union[str, None] = "0005_fix_trading_engine_trigger"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "customers",
        sa.Column("auth_provider", sa.String(length=20), nullable=False, server_default="LOCAL"),
    )
    op.add_column(
        "customers",
        sa.Column("google_id", sa.String(length=100), nullable=True),
    )
    op.create_index("ix_customers_google_id", "customers", ["google_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_customers_google_id", table_name="customers")
    op.drop_column("customers", "google_id")
    op.drop_column("customers", "auth_provider")
