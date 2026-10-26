"""Owner: TV5 - Tuệ / TV1 - Phuoc.

Transaction model representing executed trades and settlements.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, Date, DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.investment_account import InvestmentAccount
    from app.models.stock import Stock
    from app.models.stock_order import StockOrder


class Transaction(Base):
    """Transaction trade execution record."""

    __tablename__ = "transactions"

    transaction_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("stock_orders.order_id"),
        nullable=False,
    )
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
    transaction_type: Mapped[str] = mapped_column(String(10), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(20, 2), nullable=False)
    transaction_fee: Mapped[Decimal] = mapped_column(
        Numeric(20, 2), nullable=False, default=Decimal("0.00")
    )
    tax_amount: Mapped[Decimal] = mapped_column(
        Numeric(20, 2), nullable=False, default=Decimal("0.00")
    )
    net_amount: Mapped[Decimal] = mapped_column(Numeric(20, 2), nullable=False)
    transaction_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )
    settlement_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Relationships
    account: Mapped["InvestmentAccount"] = relationship(
        "InvestmentAccount", back_populates="transactions"
    )
    stock: Mapped["Stock"] = relationship("Stock", back_populates="transactions")
    order: Mapped["StockOrder"] = relationship("StockOrder", back_populates="transactions")
