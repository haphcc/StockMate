"""Owner: TV4 - LB / TV1 - Phuoc.

Stock model representing listed securities traded on exchanges.
"""

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, DateTime, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.portfolio import Portfolio
    from app.models.stock_order import StockOrder
    from app.models.stock_price_history import StockPriceHistory
    from app.models.transaction import Transaction
    from app.models.watchlist import Watchlist


class Stock(Base):
    """Stock security listed on HOSE, HNX, or UPCOM."""

    __tablename__ = "stocks"

    stock_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    stock_symbol: Mapped[str] = mapped_column(String(10), unique=True, nullable=False, index=True)
    company_name: Mapped[str] = mapped_column(String(200), nullable=False)
    exchange: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    industry: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    listed_shares: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    current_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0.00")
    )
    reference_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0.00")
    )
    ceiling_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0.00")
    )
    floor_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0.00")
    )
    total_volume: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="ACTIVE")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationships
    portfolios: Mapped[list["Portfolio"]] = relationship("Portfolio", back_populates="stock")
    orders: Mapped[list["StockOrder"]] = relationship("StockOrder", back_populates="stock")
    transactions: Mapped[list["Transaction"]] = relationship("Transaction", back_populates="stock")
    price_history: Mapped[list["StockPriceHistory"]] = relationship(
        "StockPriceHistory",
        back_populates="stock",
        cascade="all, delete-orphan",
    )
    watchlists: Mapped[list["Watchlist"]] = relationship(
        "Watchlist",
        back_populates="stock",
        cascade="all, delete-orphan",
    )
