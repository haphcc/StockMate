"""Owner: TV4 - LB. Idempotent watchlist operations scoped to the JWT customer."""

from fastapi import APIRouter, Response

from app.api.deps import CurrentUserDep, DbDep
from app.api.v1.endpoints.market import Symbol
from app.crud import watchlist
from app.crud.market import find_stock
from app.schemas.watchlist import WatchlistRequest, WatchlistResponse
from app.services.market_service import require_stock, stock_response

router = APIRouter()


def response(entry) -> WatchlistResponse:
    return WatchlistResponse(watchlist_id=entry.watchlist_id, stock=stock_response(entry.stock))


@router.get("", response_model=list[WatchlistResponse])
def get_watchlist(user: CurrentUserDep, db: DbDep) -> list[WatchlistResponse]:
    return [response(entry) for entry in watchlist.entries(db, user.customer_id)]


@router.post("", response_model=WatchlistResponse, status_code=201)
def add_watchlist(request: WatchlistRequest, user: CurrentUserDep, db: DbDep) -> WatchlistResponse:
    stock = require_stock(db, request.stock_symbol)
    return response(watchlist.add_entry(db, user.customer_id, stock.stock_id))


@router.delete("/{symbol}", status_code=204)
def delete_watchlist(symbol: Symbol, user: CurrentUserDep, db: DbDep) -> Response:
    stock = find_stock(db, symbol)
    if stock is not None:
        watchlist.remove_entries(db, user.customer_id, stock.stock_id)
    return Response(status_code=204)
