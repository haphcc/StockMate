"""Owner: TV4 - LB. Shared quote mapping for market and watchlist."""

from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.crud.market import find_stock
from app.models.stock import Stock
from app.schemas.market import StockResponse


def require_stock(db: Session, symbol: str) -> Stock:
    stock = find_stock(db, symbol)
    if stock is None:
        raise NotFoundException("Không tìm thấy mã cổ phiếu.")
    return stock


def stock_response(stock: Stock) -> StockResponse:
    price, reference = stock.current_price, stock.reference_price
    if price == reference:
        state = "REFERENCE"
    elif stock.ceiling_price > 0 and price >= stock.ceiling_price:
        state = "CEILING"
    elif stock.floor_price > 0 and price <= stock.floor_price:
        state = "FLOOR"
    else:
        state = "UP" if price > reference else "DOWN"
    return StockResponse(
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        exchange=stock.exchange,
        industry=stock.industry,
        current_price=price,
        reference_price=reference,
        ceiling_price=stock.ceiling_price,
        floor_price=stock.floor_price,
        price_change=price - reference,
        change_percent=(price - reference) * Decimal(100) / reference if reference else None,
        price_state=state,
        total_volume=stock.total_volume,
        status=stock.status,
        updated_at=stock.updated_at,
    )
