"""Add role column to customers table and set default admin user.

Revision ID: 0002_add_admin_role
Revises: 0001_baseline
Create Date: 2026-10-26 12:15:00
Owner: TV1 - Phuoc
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002_add_admin_role"
down_revision: Union[str, None] = "0001_baseline"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # Check if role column already exists
    has_role = bind.execute(
        sa.text(
            """
            SELECT COUNT(*) FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = 'customers' 
              AND column_name = 'role'
            """
        )
    ).scalar()

    if not has_role:
        op.add_column(
            "customers",
            sa.Column(
                "role",
                sa.String(length=20),
                server_default="CUSTOMER",
                nullable=False,
            ),
        )
        op.create_check_constraint(
            "ck_customers_role",
            "customers",
            "role IN ('CUSTOMER', 'ADMIN')",
        )

    # Update an.nguyen@gmail.com to ADMIN
    bind.execute(sa.text("UPDATE customers SET role = 'ADMIN' WHERE email = 'an.nguyen@gmail.com'"))


def downgrade() -> None:
    op.drop_constraint("ck_customers_role", "customers", type_="check")
    op.drop_column("customers", "role")
