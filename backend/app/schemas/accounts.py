"""Owner: TV4 - LB. Account selector response for checkpoint 1."""

from pydantic import BaseModel, ConfigDict

from app.schemas.common import Money


class AccountResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    account_id: int
    account_number: str
    account_type: str
    status: str


class AssetResponse(AccountResponse):
    cash_balance: Money
    blocked_balance: Money
    stock_value: Money
    total_asset_value: Money
    total_profit_loss: Money
    profit_loss_percent: Money | None


class PortfolioResponse(BaseModel):
    portfolio_id: int
    account_id: int
    stock_id: int
    stock_symbol: str
    company_name: str
    exchange: str
    quantity: int
    available_quantity: int
    blocked_quantity: int
    pending_quantity: int
    average_price: Money
    market_price: Money
    current_value: Money
    profit_loss: Money
    profit_loss_percent: Money | None
