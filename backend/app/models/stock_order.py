"""Owner: TV5 - Tuệ / TV1 - Phuoc.

Stock order model representing buy and sell orders placed on the exchange.
"""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.investment_account import InvestmentAccount
    from app.models.stock import Stock
    from app.models.transaction import Transaction


class StockOrder(Base):
    """Stock order placed by an account."""

    __tablename__ = "stock_orders"
    __table_args__ = (
        UniqueConstraint("account_id", "client_order_id", name="uq_orders_account_client_id"),
    )

    order_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    account_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("investment_accounts.account_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    stock_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("stocks.stock_id"),
        nullable=False,
        index=True,
    )
    client_order_id: Mapped[uuid.UUID] = mapped_column(Uuid, nullable=False, default=uuid.uuid4)
    order_type: Mapped[str] = mapped_column(String(10), nullable=False)
    order_kind: Mapped[str] = mapped_column(String(10), nullable=False, default="LO")
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    filled_quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    order_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0.00")
    )
    order_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )
    matched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="PENDING", index=True)
    reject_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Relationships
    account: Mapped["InvestmentAccount"] = relationship(
        "InvestmentAccount", back_populates="stock_orders"
    )
    stock: Mapped["Stock"] = relationship("Stock", back_populates="orders")
    transactions: Mapped[list["Transaction"]] = relationship("Transaction", back_populates="order")
