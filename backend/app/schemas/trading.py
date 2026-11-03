"""Owner: TV5 - Tuệ.

Pydantic schemas for Trading Engine, Orders, and Transactions.
Conforms strictly to API_CONTRACT.md and BUSINESS_RULES.md.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Generic, Literal, TypeVar
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_serializer

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """Standard pagination envelope."""

    items: list[T]
    page: int
    page_size: int
    total: int


class CreateOrderRequest(BaseModel):
    """Schema for placing a new stock order."""

    client_order_id: UUID = Field(
        ...,
        description="UUID do client tạo cho mỗi ý định đặt lệnh (Idempotency Key)",
    )
    stock_symbol: str = Field(
        ...,
        min_length=1,
        max_length=10,
        description="Mã cổ phiếu (ví dụ: FPT, VNM)",
    )
    order_type: Literal["BUY", "SELL"] = Field(
        ...,
        description="Loại lệnh: BUY hoặc SELL",
    )
    order_kind: Literal["LO"] = Field(
        default="LO",
        description="Kiểu lệnh (MVP chỉ hỗ trợ LO - Limit Order)",
    )
    quantity: int = Field(
        ...,
        gt=0,
        description="Khối lượng đặt mua/bán (phải là bội số của 100)",
    )
    order_price: Decimal = Field(
        ...,
        gt=0,
        description="Mức giá đặt lệnh (VND)",
    )

    @field_serializer("order_price", when_used="json")
    def serialize_price(self, v: Decimal) -> str:
        return f"{v:.2f}"


class OrderResponse(BaseModel):
    """Schema for stock order details."""

    model_config = ConfigDict(from_attributes=True)

    order_id: int
    client_order_id: UUID | None = None
    account_id: int
    stock_symbol: str
    order_type: str
    order_kind: str
    quantity: int
    filled_quantity: int
    remaining_quantity: int
    order_price: Decimal
    status: str
    reject_reason: str | None = None
    order_date: datetime
    matched_at: datetime | None = None

    @field_serializer("order_price", when_used="json")
    def serialize_order_price(self, v: Decimal) -> str:
        return f"{v:.2f}"


class TransactionResponse(BaseModel):
    """Schema for executed transaction trade record."""

    model_config = ConfigDict(from_attributes=True)

    transaction_id: int
    order_id: int
    account_id: int
    stock_symbol: str
    transaction_type: str
    quantity: int
    price: Decimal
    total_amount: Decimal
    transaction_fee: Decimal
    tax_amount: Decimal
    net_amount: Decimal
    transaction_date: datetime
    settlement_date: date | None = None

    @field_serializer(
        "price",
        "total_amount",
        "transaction_fee",
        "tax_amount",
        "net_amount",
        when_used="json",
    )
    def serialize_decimals(self, v: Decimal) -> str:
        return f"{v:.2f}"
