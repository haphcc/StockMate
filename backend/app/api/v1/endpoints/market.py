"""Owner: TV4 - LB. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.common import ERROR_RESPONSES, Exchange, Page
from app.schemas.market import CandleResponse, StockResponse

router = APIRouter(tags=["market"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)])


@router.get("/market/board", response_model=Page[StockResponse], status_code=200)
def market_board(
    exchange: Exchange | None = None,
    q: str | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    not_implemented("market_board", "TV4 - LB")


@router.get("/stocks/{symbol}", response_model=StockResponse, status_code=200)
def stock_detail(
    symbol: str,
):
    not_implemented("stock_detail", "TV4 - LB")


@router.get("/stocks/{symbol}/chart", response_model=list[CandleResponse], status_code=200)
def stock_chart(
    symbol: str,
    range: Literal["1M", "3M", "6M"] = "1M",
):
    not_implemented("stock_chart", "TV4 - LB")
