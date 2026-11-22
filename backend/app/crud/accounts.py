"""Owner: TV4 - LB. Account ownership and up-to-date valuation queries."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.investment_account import InvestmentAccount
from app.models.portfolio import Portfolio
from app.models.stock import Stock


def owned_account(db: Session, customer_id: int, account_id: int) -> InvestmentAccount | None:
    return db.scalar(
        select(InvestmentAccount).where(
            InvestmentAccount.account_id == account_id,
            InvestmentAccount.customer_id == customer_id,
        )
    )


def asset_row(db: Session, customer_id: int, account_id: int):
    totals = (
        select(
            Portfolio.account_id,
            func.sum(Portfolio.quantity * Stock.current_price).label("stock_value"),
            func.sum(Portfolio.quantity * Portfolio.average_price).label("total_cost"),
        )
        .join(Stock, Stock.stock_id == Portfolio.stock_id)
        .where(
            Portfolio.account_id == account_id,
            Portfolio.quantity > 0,
        )
        .group_by(Portfolio.account_id)
        .subquery()
    )
    # Balances and holdings use one statement snapshot, never cached NAV columns.
    return db.execute(
        select(
            InvestmentAccount,
            func.coalesce(totals.c.stock_value, 0),
            func.coalesce(totals.c.total_cost, 0),
        )
        .outerjoin(totals, totals.c.account_id == InvestmentAccount.account_id)
        .where(
            InvestmentAccount.account_id == account_id,
            InvestmentAccount.customer_id == customer_id,
        )
    ).first()


def portfolio_rows(db: Session, customer_id: int, account_id: int):
    return db.execute(
        select(Portfolio, Stock)
        .join(
            Stock,
            Stock.stock_id == Portfolio.stock_id,
        )
        .join(InvestmentAccount, InvestmentAccount.account_id == Portfolio.account_id)
        .where(
            InvestmentAccount.customer_id == customer_id,
            Portfolio.account_id == account_id,
            Portfolio.quantity > 0,
        )
        .order_by(Portfolio.portfolio_id)
    ).all()
