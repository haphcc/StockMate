"""Owner: TV4 - LB. Fresh asset/holding responses using exact Decimal arithmetic."""

from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.crud.accounts import asset_row, owned_account, portfolio_rows
from app.schemas.accounts import AssetResponse, PortfolioResponse


def assets(db: Session, customer_id: int, account_id: int) -> AssetResponse:
    row = asset_row(db, customer_id, account_id)
    if row is None:
        raise NotFoundException("Không tìm thấy tài khoản.")
    account, value, cost = row
    value, cost = Decimal(value), Decimal(cost)
    profit = value - cost
    return AssetResponse(
        account_id=account.account_id,
        account_number=account.account_number,
        account_type=account.account_type,
        status=account.status,
        cash_balance=account.cash_balance,
        blocked_balance=account.blocked_balance,
        stock_value=value,
        total_asset_value=account.cash_balance + account.blocked_balance + value,
        total_profit_loss=profit,
        profit_loss_percent=profit * Decimal(100) / cost if cost else None,
    )


def portfolio(db: Session, customer_id: int, account_id: int) -> list[PortfolioResponse]:
    if owned_account(db, customer_id, account_id) is None:
        raise NotFoundException("Không tìm thấy tài khoản.")
    result = []
    for holding, stock in portfolio_rows(db, customer_id, account_id):
        value = holding.quantity * stock.current_price
        cost = holding.quantity * holding.average_price
        profit = value - cost
        result.append(
            PortfolioResponse(
                portfolio_id=holding.portfolio_id,
                account_id=account_id,
                stock_id=stock.stock_id,
                stock_symbol=stock.stock_symbol,
                company_name=stock.company_name,
                exchange=stock.exchange,
                quantity=holding.quantity,
                available_quantity=holding.available_quantity,
                blocked_quantity=holding.blocked_quantity,
                pending_quantity=holding.quantity
                - holding.available_quantity
                - holding.blocked_quantity,
                average_price=holding.average_price,
                market_price=stock.current_price,
                current_value=value,
                profit_loss=profit,
                profit_loss_percent=profit * Decimal(100) / cost if cost else None,
            )
        )
    return result
