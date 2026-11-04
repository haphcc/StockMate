"""Owner: TV5 - Tuệ.

Settlement service handling T+2 trade clearing and share availability release.
Conforms strictly to SETTLE-01 in BUSINESS_RULES.md.
"""

from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.portfolio import Portfolio
from app.models.settlement import ShareSettlement
from app.services.notification_service import send_notification

VN_TZ = ZoneInfo("Asia/Ho_Chi_Minh")


def get_current_vn_date() -> date:
    """Get current calendar date in Asia/Ho_Chi_Minh timezone."""
    return datetime.now(VN_TZ).date()


def calculate_settlement_date(
    trade_date: date | datetime | None = None,
    business_days: int = 2,
) -> date:
    """Calculate settlement date T+N by advancing N business days (skipping Sat & Sun).

    Vietnam Stock Market rule (SETTLE-01):
    - Trade on Friday 23/10/2026 -> Tuesday 27/10/2026.
    """
    if trade_date is None:
        start_date = get_current_vn_date()
    elif isinstance(trade_date, datetime):
        if trade_date.tzinfo is not None:
            start_date = trade_date.astimezone(VN_TZ).date()
        else:
            start_date = trade_date.date()
    else:
        start_date = trade_date

    current = start_date
    added = 0
    while added < business_days:
        current += timedelta(days=1)
        if current.weekday() < 5:  # Monday(0) through Friday(4)
            added += 1

    return current


def record_buy_settlement(
    db: Session,
    transaction_id: int,
    account_id: int,
    stock_id: int,
    quantity: int,
    settlement_date: date,
) -> ShareSettlement:
    """Create a pending settlement batch for a newly executed BUY transaction."""
    settlement = ShareSettlement(
        transaction_id=transaction_id,
        account_id=account_id,
        stock_id=stock_id,
        quantity=quantity,
        settlement_date=settlement_date,
        status="PENDING",
    )
    db.add(settlement)
    return settlement


def process_share_settlements(
    db: Session,
    as_of_date: date | None = None,
) -> list[ShareSettlement]:
    """Process due T+2 settlements as of given date and release shares to available_quantity.

    Guarantees:
    - Ledger-based: each purchase batch is settled exactly once.
    - Idempotent: re-running on the same date has no effect.
    - Preserves shares blocked for pending sell orders (blocked_quantity is untouched).
    """
    if as_of_date is None:
        as_of_date = get_current_vn_date()

    # Query all pending batches due on or before as_of_date
    stmt = (
        select(ShareSettlement)
        .options(
            selectinload(ShareSettlement.stock),
            selectinload(ShareSettlement.account),
            selectinload(ShareSettlement.transaction),
        )
        .filter(
            ShareSettlement.status == "PENDING",
            ShareSettlement.settlement_date <= as_of_date,
        )
        .with_for_update()
    )
    pending_settlements = db.scalars(stmt).all()

    settled_records: list[ShareSettlement] = []
    now_utc = datetime.now(timezone.utc)

    for item in pending_settlements:
        # Find and lock portfolio record
        portfolio = (
            db.query(Portfolio)
            .filter(
                Portfolio.account_id == item.account_id,
                Portfolio.stock_id == item.stock_id,
            )
            .with_for_update()
            .first()
        )

        if portfolio:
            # Release settled quantity to available
            portfolio.available_quantity += item.quantity
            # Clamp available so it never exceeds total owned minus blocked
            max_available = portfolio.quantity - portfolio.blocked_quantity
            if portfolio.available_quantity > max_available:
                portfolio.available_quantity = max(0, max_available)

        # Mark batch as SETTLED
        item.status = "SETTLED"
        item.settled_at = now_utc
        settled_records.append(item)

        # Send notification to customer
        customer_id = item.account.customer_id
        symbol = item.stock.stock_symbol if item.stock else f"ID {item.stock_id}"
        send_notification(
            db=db,
            customer_id=customer_id,
            title=f"Cổ phiếu về tài khoản: {symbol}",
            content=(
                f"{item.quantity:,} cổ phiếu {symbol} ngày "
                f"{item.transaction.transaction_date.strftime('%d/%m/%Y')} đã về khả dụng."
            ),
            notification_type="TRANSACTION",
            ref_id=item.transaction_id,
        )

    db.commit()
    return settled_records
