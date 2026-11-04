"""Owner: TV5 - Tuệ.

CRUD database operations for Stock Orders.
"""

from uuid import UUID

from sqlalchemy import desc
from sqlalchemy.orm import Session, joinedload

from app.models.stock_order import StockOrder


def get_order_by_id(db: Session, order_id: int) -> StockOrder | None:
    """Fetch single order by primary key."""
    return (
        db.query(StockOrder)
        .options(joinedload(StockOrder.stock))
        .filter(StockOrder.order_id == order_id)
        .first()
    )


def get_order_by_client_id(
    db: Session, account_id: int, client_order_id: UUID
) -> StockOrder | None:
    """Fetch order by account_id and client_order_id (for idempotency check)."""
    return (
        db.query(StockOrder)
        .options(joinedload(StockOrder.stock))
        .filter(
            StockOrder.account_id == account_id,
            StockOrder.client_order_id == client_order_id,
        )
        .first()
    )


def get_orders_by_account(
    db: Session,
    account_id: int,
    status: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[StockOrder], int]:
    """Fetch paginated orders for an account sorted by timestamp DESC then ID DESC."""
    query = (
        db.query(StockOrder)
        .options(joinedload(StockOrder.stock))
        .filter(StockOrder.account_id == account_id)
    )

    if status:
        query = query.filter(StockOrder.status == status.upper())

    total = query.count()
    items = (
        query.order_by(desc(StockOrder.order_date), desc(StockOrder.order_id))
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return items, total
