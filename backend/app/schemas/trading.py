from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from pydantic import AwareDatetime, Field

from app.schemas.common import ContractModel, Money, OrderStatus, PositiveMoney, Symbol


class CreateOrderRequest(ContractModel):
    client_order_id: UUID
    stock_symbol: Symbol
    order_type: Literal["BUY", "SELL"]
    order_kind: Literal["LO"] = "LO"
    quantity: Annotated[int, Field(strict=True, gt=0, multiple_of=100)]
    order_price: PositiveMoney


class OrderResponse(ContractModel):
    order_id: int
    client_order_id: UUID
    account_id: int
    stock_symbol: Symbol
    order_type: Literal["BUY", "SELL"]
    order_kind: Literal["LO", "MP", "ATO", "ATC"]
    quantity: int
    filled_quantity: int
    remaining_quantity: int
    order_price: Money
    status: OrderStatus
    reject_reason: str | None = None
    order_date: AwareDatetime
    matched_at: AwareDatetime | None = None


class TransactionResponse(ContractModel):
    transaction_id: int
    order_id: int
    account_id: int
    stock_symbol: Symbol
    transaction_type: Literal["BUY", "SELL"]
    quantity: int
    price: Money
    total_amount: Money
    transaction_fee: Money
    tax_amount: Money
    net_amount: Money
    transaction_date: AwareDatetime
    settlement_date: date
