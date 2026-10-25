from typing import Literal

from app.schemas.common import ContractModel, Exchange, Money, Symbol


class AccountResponse(ContractModel):
    account_id: int
    account_number: str
    account_type: Literal["CASH", "MARGIN"]
    status: Literal["ACTIVE", "SUSPENDED", "CLOSED"]


class AssetResponse(AccountResponse):
    cash_balance: Money
    blocked_balance: Money
    stock_value: Money
    total_asset_value: Money
    total_profit_loss: Money
    profit_loss_percent: Money | None


class PortfolioResponse(ContractModel):
    portfolio_id: int
    account_id: int
    stock_id: int
    stock_symbol: Symbol
    company_name: str
    exchange: Exchange
    quantity: int
    available_quantity: int
    blocked_quantity: int
    pending_quantity: int
    average_price: Money
    market_price: Money
    current_value: Money
    profit_loss: Money
    profit_loss_percent: Money | None
