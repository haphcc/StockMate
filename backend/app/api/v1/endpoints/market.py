"""Owner: TV4 - LB. Authenticated market board, quote details and candles."""

from typing import Annotated, Literal

from fastapi import APIRouter, Path, Query

from app.api.deps import CurrentUserDep, DbDep
from app.crud.market import chart_rows, market_page
from app.schemas.common import Page
from app.schemas.market import CandleResponse, StockResponse
from app.services.market_service import require_stock, stock_response

router = APIRouter()
Symbol = Annotated[str, Path(min_length=1, max_length=10)]


@router.get("/market/board", response_model=Page[StockResponse])
def board(
    _: CurrentUserDep,
    db: DbDep,
    exchange: Literal["HOSE", "HNX", "UPCOM"] | None = None,
    q: Annotated[str | None, Query(max_length=200)] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> Page[StockResponse]:
    rows, total = market_page(db, exchange, q, page, page_size)
    return Page(
        items=[stock_response(row) for row in rows], page=page, page_size=page_size, total=total
    )


@router.get("/stocks/{symbol}", response_model=StockResponse)
def detail(symbol: Symbol, _: CurrentUserDep, db: DbDep) -> StockResponse:
    return stock_response(require_stock(db, symbol))


@router.get("/stocks/{symbol}/chart", response_model=list[CandleResponse])
def chart(
    symbol: Symbol,
    _: CurrentUserDep,
    db: DbDep,
    chart_range: Annotated[Literal["1M", "3M", "6M"], Query(alias="range")] = "1M",
) -> list[CandleResponse]:
    stock = require_stock(db, symbol)
    limit = {"1M": 22, "3M": 66, "6M": 132}[chart_range]
    return [CandleResponse.model_validate(row) for row in chart_rows(db, stock.stock_id, limit)]
