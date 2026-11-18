"""Add auth_provider and google_id columns to customers table.

Revision ID: 0006_add_google_auth_columns
Revises: 0005_fix_trading_engine_trigger
Create Date: 2026-11-18 10:50:00
Owner: TV1 - Phuoc
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0006_add_google_auth_columns"
down_revision: Union[str, None] = "0005_fix_trading_engine_trigger"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(bind, table_name: str, column_name: str) -> bool:
    return bool(
        bind.execute(
            sa.text(
                """
                SELECT COUNT(*) FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = :table_name
                  AND column_name = :column_name
                """
            ),
            {"table_name": table_name, "column_name": column_name},
        ).scalar()
    )


def upgrade() -> None:
    bind = op.get_bind()

    if not _has_column(bind, "customers", "auth_provider"):
        op.add_column(
            "customers",
            sa.Column(
                "auth_provider",
                sa.String(length=20),
                server_default="LOCAL",
                nullable=False,
            ),
        )
        op.create_check_constraint(
            "ck_customers_auth_provider",
            "customers",
            "auth_provider IN ('LOCAL', 'GOOGLE')",
        )

    if not _has_column(bind, "customers", "google_id"):
        op.add_column(
            "customers",
            sa.Column(
                "google_id",
                sa.String(length=255),
                nullable=True,
            ),
        )
        op.create_unique_constraint("uq_customers_google_id", "customers", ["google_id"])

    # Backfill any previously provisioned Google OAuth accounts.
    bind.execute(
        sa.text(
            """
            UPDATE customers
            SET auth_provider = 'GOOGLE'
            WHERE password_hash = 'GOOGLE_OAUTH_ACCOUNT'
              AND auth_provider <> 'GOOGLE'
            """
        )
    )


def downgrade() -> None:
    bind = op.get_bind()

    if _has_column(bind, "customers", "google_id"):
        op.drop_constraint("uq_customers_google_id", "customers", type_="unique")
        op.drop_column("customers", "google_id")

    if _has_column(bind, "customers", "auth_provider"):
        op.drop_constraint("ck_customers_auth_provider", "customers", type_="check")
        op.drop_column("customers", "auth_provider")
