"""Owner: TV4 - LB. Authenticated market board, quote details and candles."""

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Path, Query
from pydantic import BaseModel

from app.api.deps import CurrentUserDep, DbDep
from app.crud.market import chart_rows, market_page
from app.schemas.common import Page
from app.schemas.market import CandleResponse, StockResponse
from app.services.market_service import require_stock, stock_response
from app.services.realtime_market import (
    fetch_live_candles,
    fetch_live_stock_quote,
    sync_all_active_stocks,
    sync_stock_with_live_data,
)

router = APIRouter()
Symbol = Annotated[str, Path(min_length=1, max_length=10)]


class SyncLiveRequest(BaseModel):
    symbols: list[str] | None = None


class SyncLiveResponse(BaseModel):
    total: int
    synced_count: int
    failed_count: int
    synced_symbols: list[str]
    failed_symbols: list[str]


@router.get("/market/board", response_model=Page[StockResponse])
def board(
    _: CurrentUserDep,
    db: DbDep,
    exchange: Literal["HOSE", "HNX", "UPCOM"] | None = None,
    q: Annotated[str | None, Query(max_length=200)] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    live: bool = Query(False, description="Fetch and sync real-time quotes for current page"),
) -> Page[StockResponse]:
    rows, total = market_page(db, exchange, q, page, page_size)
    items: list[StockResponse] = []
    for row in rows:
        if live:
            live_quote = fetch_live_stock_quote(row.stock_symbol)
            if live_quote:
                sync_stock_with_live_data(db, row, live_quote)
                items.append(stock_response(row, data_source="LIVE", is_stale=False))
                continue
        items.append(stock_response(row))
    return Page(items=items, page=page, page_size=page_size, total=total)


@router.get("/stocks/{symbol}", response_model=StockResponse)
def detail(
    symbol: Symbol,
    _: CurrentUserDep,
    db: DbDep,
    live: bool = Query(False, description="Fetch real-time market data from exchange"),
) -> StockResponse:
    stock = require_stock(db, symbol)
    if live:
        live_quote = fetch_live_stock_quote(stock.stock_symbol)
        if live_quote:
            sync_stock_with_live_data(db, stock, live_quote)
            return stock_response(stock, data_source="LIVE", is_stale=False)
    return stock_response(stock)


@router.get("/stocks/{symbol}/chart", response_model=list[CandleResponse])
def chart(
    symbol: Symbol,
    _: CurrentUserDep,
    db: DbDep,
    chart_range: Annotated[Literal["1M", "3M", "6M"], Query(alias="range")] = "1M",
    live: bool = Query(False, description="Fetch real-time daily candles from exchange"),
) -> list[CandleResponse]:
    stock = require_stock(db, symbol)
    limit = {"1M": 22, "3M": 66, "6M": 132}[chart_range]
    if live:
        live_candles = fetch_live_candles(stock.stock_symbol, limit)
        if live_candles:
            return live_candles
    return [CandleResponse.model_validate(row) for row in chart_rows(db, stock.stock_id, limit)]


@router.post("/market/sync-live", response_model=SyncLiveResponse)
def sync_live_market(
    _: CurrentUserDep,
    db: DbDep,
    payload: SyncLiveRequest | None = None,
) -> Any:
    """Sync real-time stock prices from live exchange feed into database."""
    symbols = payload.symbols if payload else None
    return sync_all_active_stocks(db, symbols)
