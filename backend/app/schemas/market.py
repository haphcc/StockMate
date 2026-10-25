from datetime import date
from typing import Literal

from pydantic import AwareDatetime

from app.schemas.common import ContractModel, Exchange, Money, Symbol


class StockResponse(ContractModel):
    stock_id: int
    stock_symbol: Symbol
    company_name: str
    exchange: Exchange
    industry: str | None = None
    current_price: Money
    reference_price: Money
    ceiling_price: Money
    floor_price: Money
    price_change: Money
    change_percent: Money
    price_state: Literal["CEILING", "FLOOR", "REFERENCE", "UP", "DOWN"]
    total_volume: int
    status: Literal["ACTIVE", "HALTED", "DELISTED"]
    updated_at: AwareDatetime
    data_source: Literal["DEMO", "LIVE"]
    is_stale: bool


class CandleResponse(ContractModel):
    recorded_date: date
    open_price: Money
    close_price: Money
    highest_price: Money
    lowest_price: Money
    trading_volume: int
