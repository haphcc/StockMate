"""Owner: TV4 - LB. Authenticated market board, quote details and candles."""

import logging
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Path, Query
from pydantic import BaseModel, Field

from app.api.deps import CurrentUserDep, DbDep
from app.crud.market import chart_rows, market_page
from app.schemas.common import Page
from app.schemas.market import CandleResponse, StockResponse
from app.services.market_service import require_stock, stock_response
from app.services.realtime_market import (
    fetch_live_candles,
    fetch_live_quotes_by_exchange,
    fetch_live_stock_quote,
    merge_candles_with_intraday,
    sync_all_active_stocks,
    sync_stock_with_live_data,
    upsert_price_history_candles,
)

logger = logging.getLogger(__name__)
router = APIRouter()
Symbol = Annotated[str, Path(min_length=1, max_length=10)]


class SyncLiveRequest(BaseModel):
    symbols: list[str] | None = None
    include_history: bool = False
    history_limit: int = Field(default=132, ge=1, le=260)


class SyncLiveResponse(BaseModel):
    total: int
    synced_count: int
    failed_count: int
    synced_symbols: list[str]
    failed_symbols: list[str]
    candles_synced: int = 0


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
    batch_quotes: dict[str, dict[str, Any]] = {}
    if live and rows:
        exchanges = {row.exchange for row in rows if row.exchange}
        batch_quotes = fetch_live_quotes_by_exchange(exchanges)

    items: list[StockResponse] = []
    updated_any = False
    for row in rows:
        if live:
            live_quote = batch_quotes.get(row.stock_symbol)
            if live_quote is None and len(rows) <= 5:
                live_quote = fetch_live_stock_quote(row.stock_symbol)
            if live_quote:
                sync_stock_with_live_data(db, row, live_quote, commit=False)
                updated_any = True
                items.append(stock_response(row, data_source="LIVE", is_stale=False))
                continue
        items.append(stock_response(row))

    if updated_any:
        try:
            db.commit()
        except Exception as exc:
            logger.debug("Failed to commit batch live quotes: %s", exc)
            db.rollback()

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
        live_quote = fetch_live_stock_quote(stock.stock_symbol)
        merged_candles, trading_values = merge_candles_with_intraday(
            live_candles, live_quote, limit=limit
        )
        if merged_candles:
            try:
                if live_quote:
                    sync_stock_with_live_data(db, stock, live_quote, commit=False)
                upsert_price_history_candles(
                    db,
                    stock,
                    merged_candles,
                    trading_values=trading_values,
                    commit=True,
                )
            except Exception as exc:
                logger.debug("Failed to persist live candles for %s: %s", stock.stock_symbol, exc)
                db.rollback()
            return merged_candles
    return [CandleResponse.model_validate(row) for row in chart_rows(db, stock.stock_id, limit)]


@router.post("/market/sync-live", response_model=SyncLiveResponse)
def sync_live_market(
    _: CurrentUserDep,
    db: DbDep,
    payload: SyncLiveRequest | None = None,
) -> Any:
    """Sync real-time stock prices (and optionally daily candle history) into database."""
    symbols = payload.symbols if payload else None
    include_history = payload.include_history if payload else False
    history_limit = payload.history_limit if payload else 132
    return sync_all_active_stocks(
        db,
        symbols,
        include_history=include_history,
        history_limit=history_limit,
    )
