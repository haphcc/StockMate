"""Owner: TV4 - LB / TV1 - Phuoc.

Stock price history model recording daily OHLCV candlestick data.
"""

from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, Date, ForeignKey, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.stock import Stock


class StockPriceHistory(Base):
    """Daily OHLCV candlestick history record for listed stocks."""

    __tablename__ = "stock_price_history"
    __table_args__ = (UniqueConstraint("stock_id", "recorded_date", name="uq_price_history"),)

    price_history_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("stocks.stock_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    recorded_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    open_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    close_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    highest_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    lowest_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    trading_volume: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    trading_value: Mapped[Decimal] = mapped_column(
        Numeric(20, 2), nullable=False, default=Decimal("0.00")
    )

    # Relationships
    stock: Mapped["Stock"] = relationship("Stock", back_populates="price_history")
