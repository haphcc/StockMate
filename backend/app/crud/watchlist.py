"""Owner: TV4 - LB. One API watchlist, including legacy seed list names."""

from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session, joinedload

from app.models.customer import Customer
from app.models.watchlist import Watchlist

DEFAULT_LIST = "Danh muc theo doi"


def entries(db: Session, customer_id: int) -> list[Watchlist]:
    ids = (
        select(func.min(Watchlist.watchlist_id))
        .where(
            Watchlist.customer_id == customer_id,
        )
        .group_by(Watchlist.stock_id)
    )
    return list(
        db.scalars(
            select(Watchlist)
            .options(joinedload(Watchlist.stock))
            .where(
                Watchlist.watchlist_id.in_(ids),
            )
            .order_by(Watchlist.watchlist_id)
        )
    )


def find_entry(db: Session, customer_id: int, stock_id: int) -> Watchlist | None:
    return db.scalar(
        select(Watchlist)
        .options(joinedload(Watchlist.stock))
        .where(
            Watchlist.customer_id == customer_id,
            Watchlist.stock_id == stock_id,
        )
        .order_by(Watchlist.watchlist_id)
        .limit(1)
    )


def add_entry(db: Session, customer_id: int, stock_id: int) -> Watchlist:
    # Serialize this customer's edits, including simultaneous add vs. delete.
    db.scalar(
        select(Customer.customer_id)
        .where(
            Customer.customer_id == customer_id,
        )
        .with_for_update()
    )
    existing = find_entry(db, customer_id, stock_id)
    if existing:
        return existing
    db.execute(
        insert(Watchlist)
        .values(
            customer_id=customer_id,
            stock_id=stock_id,
            list_name=DEFAULT_LIST,
        )
        .on_conflict_do_nothing(constraint="uq_watchlist")
    )
    db.commit()
    return find_entry(db, customer_id, stock_id)


def remove_entries(db: Session, customer_id: int, stock_id: int) -> None:
    db.scalar(
        select(Customer.customer_id)
        .where(
            Customer.customer_id == customer_id,
        )
        .with_for_update()
    )
    db.execute(
        delete(Watchlist).where(
            Watchlist.customer_id == customer_id,
            Watchlist.stock_id == stock_id,
        )
    )
    db.commit()
