"""Owner: TV4 - LB / TV1 - Phuoc.

Watchlist model representing customer stock watchlists and price alerts.
"""

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.stock import Stock


class Watchlist(Base):
    """Watchlist entry linking customer to tracked stocks."""

    __tablename__ = "watchlists"
    __table_args__ = (
        UniqueConstraint("customer_id", "stock_id", "list_name", name="uq_watchlist"),
    )

    watchlist_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    customer_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("customers.customer_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    stock_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("stocks.stock_id", ondelete="CASCADE"),
        nullable=False,
    )
    list_name: Mapped[str] = mapped_column(String(50), nullable=False, default="Danh muc theo doi")
    target_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", back_populates="watchlists")
    stock: Mapped["Stock"] = relationship("Stock", back_populates="watchlists")
