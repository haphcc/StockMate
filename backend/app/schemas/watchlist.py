"""Owner: TV4 - LB. Default watchlist request and nested quote response."""

from pydantic import BaseModel, Field, field_validator

from app.schemas.market import StockResponse


class WatchlistRequest(BaseModel):
    stock_symbol: str = Field(min_length=1, max_length=10, pattern=r"^[A-Z0-9]+$")

    @field_validator("stock_symbol", mode="before")
    @classmethod
    def normalize_symbol(cls, value: object) -> object:
        return value.strip().upper() if isinstance(value, str) else value


class WatchlistResponse(BaseModel):
    watchlist_id: int
    stock: StockResponse
