"""Owner: TV5 - Tuệ.

Matching Engine service for stock orders.
Conforms strictly to CASH-01, SHARE-01, and STATE-01 in BUSINESS_RULES.md.
"""

from datetime import datetime, timezone
from decimal import ROUND_HALF_UP, Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.investment_account import InvestmentAccount
from app.models.portfolio import Portfolio
from app.models.stock import Stock
from app.models.stock_order import StockOrder
from app.models.transaction import Transaction
from app.services.notification_service import send_notification
from app.services.settlement_service import (
    calculate_settlement_date,
    record_buy_settlement,
)


def compute_trading_fee(amount: Decimal) -> Decimal:
    """Calculate 0.15% transaction fee rounded HALF_UP to 0.01 VND."""
    return (amount * Decimal("0.0015")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def compute_sell_tax(amount: Decimal) -> Decimal:
    """Calculate 0.1% personal income tax for sales rounded HALF_UP to 0.01 VND."""
    return (amount * Decimal("0.0010")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def recalc_account_asset(db: Session, account_id: int) -> None:
    """Recalculate account total_asset_value = cash + blocked + sum(portfolio.current_value)."""
    account = (
        db.query(InvestmentAccount)
        .filter(InvestmentAccount.account_id == account_id)
        .with_for_update()
        .first()
    )
    if not account:
        return

    portfolios = (
        db.query(Portfolio)
        .filter(Portfolio.account_id == account_id)
        .all()
    )
    portfolio_value = sum((p.current_value for p in portfolios), Decimal("0.00"))
    account.total_asset_value = account.cash_balance + account.blocked_balance + portfolio_value


def match_order(
    db: Session,
    order: StockOrder,
    custom_price: Decimal | None = None,
) -> Transaction | None:
    """Attempt to match a single PENDING order against market conditions.

    Rules:
    - BUY matches when current_price <= limit_price; executed at current_price.
    - SELL matches when current_price >= limit_price; executed at current_price.
    - Strict locking order: Account -> Stock -> Portfolio -> Order.
    - Balance and holding adjustments are applied via trigger fn_apply_transaction.
    """
    if order.status != "PENDING":
        return None

    # 1. Lock Account
    account = (
        db.query(InvestmentAccount)
        .filter(InvestmentAccount.account_id == order.account_id)
        .with_for_update()
        .first()
    )
    if not account or account.status != "ACTIVE":
        return None

    # 2. Lock Stock
    stock = (
        db.query(Stock)
        .filter(Stock.stock_id == order.stock_id)
        .with_for_update()
        .first()
    )
    if not stock or stock.status != "ACTIVE":
        return None

    # 3. Lock Portfolio (if exists)
    portfolio = (
        db.query(Portfolio)
        .filter(
            Portfolio.account_id == order.account_id,
            Portfolio.stock_id == order.stock_id,
        )
        .with_for_update()
        .first()
    )

    current_price = custom_price if custom_price is not None else stock.current_price
    now_utc = datetime.now(timezone.utc)

    if order.order_type == "BUY":
        # Condition: market price <= limit price
        if current_price > order.order_price:
            return None

        exec_price = current_price
        gross = order.quantity * exec_price
        actual_fee = compute_trading_fee(gross)
        actual_total = gross + actual_fee

        # Calculate settlement date (T+2)
        settle_date = calculate_settlement_date(now_utc, business_days=2)

        # Create Transaction (trigger fn_apply_transaction updates account & portfolio)
        txn = Transaction(
            order_id=order.order_id,
            account_id=account.account_id,
            stock_id=stock.stock_id,
            transaction_type="BUY",
            quantity=order.quantity,
            price=exec_price,
            total_amount=gross,
            transaction_fee=actual_fee,
            tax_amount=Decimal("0.00"),
            net_amount=actual_total,
            transaction_date=now_utc,
            settlement_date=settle_date,
        )
        db.add(txn)
        db.flush()

        # Record T+2 settlement batch
        record_buy_settlement(
            db=db,
            transaction_id=txn.transaction_id,
            account_id=account.account_id,
            stock_id=stock.stock_id,
            quantity=order.quantity,
            settlement_date=settle_date,
        )

        notif_content = (
            f"Mua {order.quantity} {stock.stock_symbol} giá {exec_price:,.0f}, "
            f"phí {actual_fee:,.0f}."
        )

    elif order.order_type == "SELL":
        # Condition: market price >= limit price
        if current_price < order.order_price:
            return None

        if not portfolio or portfolio.blocked_quantity < order.quantity:
            return None

        exec_price = current_price
        gross = order.quantity * exec_price
        fee = compute_trading_fee(gross)
        tax = compute_sell_tax(gross)
        net_proceeds = gross - fee - tax

        # Create Transaction (trigger fn_apply_transaction updates account & portfolio)
        txn = Transaction(
            order_id=order.order_id,
            account_id=account.account_id,
            stock_id=stock.stock_id,
            transaction_type="SELL",
            quantity=order.quantity,
            price=exec_price,
            total_amount=gross,
            transaction_fee=fee,
            tax_amount=tax,
            net_amount=net_proceeds,
            transaction_date=now_utc,
            settlement_date=now_utc.date(),
        )
        db.add(txn)
        db.flush()

        notif_content = (
            f"Bán {order.quantity} {stock.stock_symbol} giá {exec_price:,.0f}, "
            f"phí {fee:,.0f}, thuế {tax:,.0f}."
        )
    else:
        return None

    # Update Stock total trading volume
    stock.total_volume += order.quantity

    # Deliver Notification
    send_notification(
        db=db,
        customer_id=account.customer_id,
        title=f"Khớp lệnh {order.order_type} {stock.stock_symbol}",
        content=notif_content,
        notification_type="TRANSACTION",
        ref_id=txn.transaction_id,
    )

    db.commit()
    db.refresh(order)
    db.refresh(txn)
    db.refresh(account)
    return txn


def match_all_pending_orders(
    db: Session,
    stock_id: int | None = None,
) -> list[Transaction]:
    """Scan and match all pending orders eligible under current market prices."""
    stmt = (
        select(StockOrder)
        .filter(StockOrder.status == "PENDING")
        .order_by(StockOrder.order_date.asc())
    )
    if stock_id is not None:
        stmt = stmt.filter(StockOrder.stock_id == stock_id)

    pending_orders = db.scalars(stmt).all()
    executed_transactions: list[Transaction] = []

    for o in pending_orders:
        txn = match_order(db, o)
        if txn:
            executed_transactions.append(txn)

    return executed_transactions
