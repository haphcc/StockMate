"""Owner: TV4 - LB. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from fastapi import APIRouter, Depends

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.common import ERROR_RESPONSES
from app.schemas.watchlist import AddWatchlistRequest, WatchlistResponse

router = APIRouter(
    tags=["watchlist"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)]
)


@router.get("/watchlist", response_model=list[WatchlistResponse], status_code=200)
def watchlist():
    not_implemented("watchlist", "TV4 - LB")


@router.post("/watchlist", response_model=WatchlistResponse, status_code=201)
def add_watchlist(
    payload: AddWatchlistRequest,
):
    not_implemented("add_watchlist", "TV4 - LB")


@router.delete("/watchlist/{symbol}", status_code=204)
def remove_watchlist(
    symbol: str,
):
    not_implemented("remove_watchlist", "TV4 - LB")
