"""Owner: TV4 - LB. Quotes and daily candles from the DEMO database."""

from datetime import date, datetime, timezone
from typing import Literal

from pydantic import BaseModel, ConfigDict, field_serializer

from app.schemas.common import Money


class StockResponse(BaseModel):
    stock_id: int
    stock_symbol: str
    company_name: str
    exchange: str
    industry: str | None
    current_price: Money
    reference_price: Money
    ceiling_price: Money
    floor_price: Money
    price_change: Money
    change_percent: Money | None
    price_state: Literal["CEILING", "FLOOR", "REFERENCE", "UP", "DOWN"]
    total_volume: int
    status: str
    updated_at: datetime
    data_source: Literal["DEMO"] = "DEMO"
    is_stale: bool = True

    @field_serializer("updated_at")
    def utc_timestamp(self, value: datetime) -> str:
        return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


class CandleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    recorded_date: date
    open_price: Money
    close_price: Money
    highest_price: Money
    lowest_price: Money
    trading_volume: int
