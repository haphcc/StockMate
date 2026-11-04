"""Owner: TV4 - LB. Market queries with stable ordering and literal search."""

from sqlalchemy import func, or_, select, true
from sqlalchemy.orm import Session, aliased

from app.models.stock import Stock
from app.models.stock_price_history import StockPriceHistory


def find_stock(db: Session, symbol: str) -> Stock | None:
    return db.scalar(select(Stock).where(Stock.stock_symbol == symbol.strip().upper()))


def market_page(db: Session, exchange: str | None, q: str | None, page: int, page_size: int):
    filters = []
    if exchange:
        filters.append(Stock.exchange == exchange)
    if q and q.strip():
        filters.append(
            or_(
                Stock.stock_symbol.icontains(q.strip(), autoescape=True),
                Stock.company_name.icontains(q.strip(), autoescape=True),
            )
        )
    # Count and page come from the same SQL snapshot, even during Admin updates.
    filtered = select(Stock).where(*filters).cte("filtered_stocks")
    total = select(func.count().label("total")).select_from(filtered).cte("stock_count")
    page_rows = (
        select(filtered)
        .order_by(
            filtered.c.total_volume.desc(),
            filtered.c.stock_symbol.asc(),
        )
        .offset((page - 1) * page_size)
        .limit(page_size)
        .subquery()
    )
    stock = aliased(Stock, page_rows)
    rows = db.execute(
        select(total.c.total, stock)
        .select_from(
            total.outerjoin(page_rows, true()),
        )
        .order_by(page_rows.c.total_volume.desc(), page_rows.c.stock_symbol.asc())
    ).all()
    return [row[1] for row in rows if row[1] is not None], rows[0][0]


def chart_rows(db: Session, stock_id: int, limit: int) -> list[StockPriceHistory]:
    recent = list(
        db.scalars(
            select(StockPriceHistory)
            .where(
                StockPriceHistory.stock_id == stock_id,
            )
            .order_by(StockPriceHistory.recorded_date.desc())
            .limit(limit)
        )
    )
    return list(reversed(recent))
