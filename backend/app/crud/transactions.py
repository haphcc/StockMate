"""Owner: TV5 - Tuệ.

CRUD database operations for Transactions.
"""

from sqlalchemy import desc
from sqlalchemy.orm import Session, joinedload

from app.models.transaction import Transaction


def get_transaction_by_id(db: Session, transaction_id: int) -> Transaction | None:
    """Fetch single transaction by ID."""
    return (
        db.query(Transaction)
        .options(joinedload(Transaction.stock))
        .filter(Transaction.transaction_id == transaction_id)
        .first()
    )


def get_transactions_by_account(
    db: Session,
    account_id: int,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[Transaction], int]:
    """Fetch paginated transactions for an account sorted by timestamp DESC then ID DESC."""
    query = (
        db.query(Transaction)
        .options(joinedload(Transaction.stock))
        .filter(Transaction.account_id == account_id)
    )

    total = query.count()
    items = (
        query.order_by(desc(Transaction.transaction_date), desc(Transaction.transaction_id))
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return items, total
