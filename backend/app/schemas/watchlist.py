from app.schemas.common import ContractModel, Symbol
from app.schemas.market import StockResponse


class AddWatchlistRequest(ContractModel):
    stock_symbol: Symbol


class WatchlistResponse(ContractModel):
    watchlist_id: int
    stock: StockResponse
