"""Owner: TV5 - Tuệ.

Share settlement model tracking T+2 settlement batches for bought shares.
Conforms to SETTLE-01 in BUSINESS_RULES.md.
"""

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, Date, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.investment_account import InvestmentAccount
    from app.models.stock import Stock
    from app.models.transaction import Transaction


class ShareSettlement(Base):
    """Ledger tracking individual purchase batches awaiting T+2 share delivery."""

    __tablename__ = "share_settlements"

    settlement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    transaction_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("transactions.transaction_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    account_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("investment_accounts.account_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    stock_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("stocks.stock_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    settlement_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="PENDING", index=True
    )  # PENDING / SETTLED
    settled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    # Relationships
    transaction: Mapped["Transaction"] = relationship("Transaction")
    account: Mapped["InvestmentAccount"] = relationship("InvestmentAccount")
    stock: Mapped["Stock"] = relationship("Stock")
