"""Owner: TV5 - Tuệ.

Order processing and validation service.
Conforms strictly to ORD-01, CASH-01, SHARE-01, and STATE-01 in BUSINESS_RULES.md.
"""

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.errors import (
    ConflictException,
    NotFoundException,
    ValidationException,
)
from app.crud.orders import get_order_by_client_id, get_orders_by_account
from app.crud.transactions import get_transactions_by_account
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.models.portfolio import Portfolio
from app.models.stock import Stock
from app.models.stock_order import StockOrder
from app.schemas.trading import (
    CreateOrderRequest,
    OrderResponse,
    Page,
    TransactionResponse,
)
from app.services.matching_service import compute_trading_fee, match_order, recalc_account_asset
from app.services.notification_service import send_notification


def get_price_tick(exchange: str, price: Decimal) -> Decimal:
    """Determine price tick step based on exchange rules.

    HOSE:
      < 10,000    -> 10
      < 50,000    -> 50
      >= 50,000   -> 100
    HNX / UPCOM:  -> 100
    """
    if exchange.upper() != "HOSE":
        return Decimal("100.00")
    if price < Decimal("10000.00"):
        return Decimal("10.00")
    if price < Decimal("50000.00"):
        return Decimal("50.00")
    return Decimal("100.00")


def validate_order_rules(stock: Stock, req: CreateOrderRequest) -> None:
    """Validate trading constraints before accepting order into system."""
    # MVP only supports LO (Limit Order)
    if req.order_kind != "LO":
        raise ValidationException(
            message="Hệ thống MVP hiện chỉ hỗ trợ lệnh giới hạn (LO).",
            code="UNSUPPORTED_ORDER_KIND",
        )

    # Quantity validation (lot size 100)
    if req.quantity <= 0 or req.quantity % 100 != 0:
        raise ValidationException(
            message="Khối lượng đặt phải là số nguyên dương và là bội số của 100.",
            code="VALIDATION_ERROR",
        )

    # Stock trading status
    if stock.status != "ACTIVE":
        raise ConflictException(
            message=f"Mã cổ phiếu {stock.stock_symbol} đang tạm ngừng giao dịch.",
            code="STOCK_INACTIVE",
        )

    # Price range validation (floor <= order_price <= ceiling)
    if not (stock.floor_price <= req.order_price <= stock.ceiling_price):
        raise ValidationException(
            message=(
                f"Giá đặt ({req.order_price:,.0f}) phải nằm trong biên độ trần/sàn "
                f"({stock.floor_price:,.0f} - {stock.ceiling_price:,.0f})."
            ),
            code="PRICE_OUT_OF_BAND",
        )

    # Price tick step validation
    tick = get_price_tick(stock.exchange, req.order_price)
    if (req.order_price % tick) != Decimal("0.00"):
        raise ValidationException(
            message=(
                f"Giá đặt ({req.order_price:,.0f}) không đúng bước giá quy định của sàn "
                f"{stock.exchange} ({tick:,.0f} đồng)."
            ),
            code="INVALID_PRICE_TICK",
        )


def verify_account_ownership(
    db: Session,
    customer: Customer,
    account_id: int,
) -> InvestmentAccount:
    """Validate that the investment account exists and belongs to the customer."""
    account = (
        db.query(InvestmentAccount)
        .filter(
            InvestmentAccount.account_id == account_id,
            InvestmentAccount.customer_id == customer.customer_id,
        )
        .first()
    )
    if not account:
        raise NotFoundException(
            message="Không tìm thấy tài khoản đầu tư hoặc bạn không có quyền truy cập.",
            code="ACCOUNT_NOT_FOUND",
        )

    if account.status != "ACTIVE":
        raise ConflictException(
            message="Tài khoản đầu tư này đang bị tạm dừng hoặc đã đóng.",
            code="ACCOUNT_SUSPENDED",
        )

    return account


def place_order(
    db: Session,
    customer: Customer,
    account_id: int,
    req: CreateOrderRequest,
) -> tuple[StockOrder, bool]:
    """Place a new stock order with balance reservation and idempotency guarantee.

    Returns:
        tuple[StockOrder, bool]: (order, is_new_order)
    """
    account = verify_account_ownership(db, customer, account_id)

    # Check Idempotency via (account_id, client_order_id)
    existing_order = get_order_by_client_id(db, account.account_id, req.client_order_id)
    if existing_order:
        # Check if identical payload
        stock = existing_order.stock
        is_same = (
            stock
            and stock.stock_symbol.upper() == req.stock_symbol.upper()
            and existing_order.order_type == req.order_type
            and existing_order.order_kind == req.order_kind
            and existing_order.quantity == req.quantity
            and existing_order.order_price == req.order_price
        )
        if is_same:
            return existing_order, False
        raise ConflictException(
            message="client_order_id đã tồn tại với thông tin lệnh khác.",
            code="IDEMPOTENCY_CONFLICT",
        )

    # Find stock
    stock = (
        db.query(Stock)
        .filter(Stock.stock_symbol == req.stock_symbol.upper())
        .with_for_update()
        .first()
    )
    if not stock:
        raise NotFoundException(
            message=f"Không tìm thấy mã cổ phiếu '{req.stock_symbol}'.",
            code="STOCK_NOT_FOUND",
        )

    # Validate business rules
    validate_order_rules(stock, req)

    # Lock account row
    locked_account = (
        db.query(InvestmentAccount)
        .filter(InvestmentAccount.account_id == account.account_id)
        .with_for_update()
        .first()
    )
    if not locked_account:
        raise NotFoundException(message="Không thể khóa tài khoản.", code="ACCOUNT_NOT_FOUND")

    now_utc = datetime.now(timezone.utc)

    if req.order_type == "BUY":
        gross = req.quantity * req.order_price
        fee = compute_trading_fee(gross)
        reserve = gross + fee

        if locked_account.cash_balance < reserve:
            raise ConflictException(
                message=(
                    f"Số dư tiền không đủ đặt mua. Cần {reserve:,.0f} VND "
                    f"(gồm phí tạm tính), hiện có {locked_account.cash_balance:,.0f} VND."
                ),
                code="INSUFFICIENT_CASH",
            )

        # Reserve funds
        locked_account.cash_balance -= reserve
        locked_account.blocked_balance += reserve

    elif req.order_type == "SELL":
        # Check portfolio holdings
        portfolio = (
            db.query(Portfolio)
            .filter(
                Portfolio.account_id == locked_account.account_id,
                Portfolio.stock_id == stock.stock_id,
            )
            .with_for_update()
            .first()
        )
        if not portfolio or portfolio.available_quantity < req.quantity:
            avail = portfolio.available_quantity if portfolio else 0
            raise ConflictException(
                message=(
                    f"Số lượng cổ phiếu khả dụng không đủ để đặt lệnh bán. "
                    f"Cần {req.quantity:,} cổ phiếu, hiện khả dụng {avail:,} cổ phiếu."
                ),
                code="INSUFFICIENT_SHARES",
            )

        # Block shares for selling
        portfolio.available_quantity -= req.quantity
        portfolio.blocked_quantity += req.quantity

    # Create StockOrder
    order = StockOrder(
        account_id=locked_account.account_id,
        stock_id=stock.stock_id,
        client_order_id=req.client_order_id,
        order_type=req.order_type,
        order_kind=req.order_kind,
        quantity=req.quantity,
        filled_quantity=0,
        order_price=req.order_price,
        status="PENDING",
        order_date=now_utc,
    )
    db.add(order)
    db.flush()

    # Deliver order placement notification
    send_notification(
        db=db,
        customer_id=customer.customer_id,
        title=f"Đặt lệnh {req.order_type} {stock.stock_symbol}",
        content=(
            f"Đã ghi nhận lệnh {req.order_type} {req.quantity:,} {stock.stock_symbol} "
            f"giá {req.order_price:,.0f} VND."
        ),
        notification_type="ORDER",
        ref_id=order.order_id,
    )

    db.commit()
    db.refresh(order)

    # Immediately attempt matching against simulated market price
    match_order(db, order)
    db.refresh(order)

    return order, True


def cancel_order(
    db: Session,
    customer: Customer,
    order_id: int,
) -> StockOrder:
    """Cancel a pending stock order and release blocked cash or shares."""
    order = db.query(StockOrder).filter(StockOrder.order_id == order_id).with_for_update().first()
    if not order:
        raise NotFoundException(message="Không tìm thấy lệnh yêu cầu.", code="ORDER_NOT_FOUND")

    # Verify ownership
    account = (
        db.query(InvestmentAccount)
        .filter(
            InvestmentAccount.account_id == order.account_id,
            InvestmentAccount.customer_id == customer.customer_id,
        )
        .with_for_update()
        .first()
    )
    if not account:
        raise NotFoundException(
            message="Bạn không có quyền can thiệp vào lệnh này.",
            code="ORDER_NOT_FOUND",
        )

    # Idempotent cancel: if already cancelled, return 200
    if order.status == "CANCELLED":
        return order

    if order.status != "PENDING":
        raise ConflictException(
            message=f"Lệnh đang ở trạng thái {order.status}, không thể hủy.",
            code="ORDER_NOT_CANCELLABLE",
        )

    stock = db.query(Stock).filter(Stock.stock_id == order.stock_id).first()
    symbol = stock.stock_symbol if stock else f"Stock {order.stock_id}"

    # Release blocked funds or shares
    if order.order_type == "BUY":
        gross = order.quantity * order.order_price
        fee = compute_trading_fee(gross)
        reserve = gross + fee

        account.blocked_balance -= reserve
        if account.blocked_balance < Decimal("0.00"):
            account.blocked_balance = Decimal("0.00")
        account.cash_balance += reserve

    elif order.order_type == "SELL":
        portfolio = (
            db.query(Portfolio)
            .filter(
                Portfolio.account_id == account.account_id,
                Portfolio.stock_id == order.stock_id,
            )
            .with_for_update()
            .first()
        )
        if portfolio:
            portfolio.blocked_quantity -= order.quantity
            if portfolio.blocked_quantity < 0:
                portfolio.blocked_quantity = 0
            portfolio.available_quantity += order.quantity

    order.status = "CANCELLED"
    recalc_account_asset(db, account.account_id)

    send_notification(
        db=db,
        customer_id=customer.customer_id,
        title=f"Hủy lệnh {order.order_type} {symbol}",
        content=(
            f"Lệnh {order.order_type} {order.quantity:,} {symbol} "
            f"đã được hủy và giải tỏa tài sản thành công."
        ),
        notification_type="ORDER",
        ref_id=order.order_id,
    )

    db.commit()
    db.refresh(order)
    return order


def build_order_response(order: StockOrder) -> OrderResponse:
    """Build response model with computed fields."""
    stock_symbol = order.stock.stock_symbol if order.stock else ""
    return OrderResponse(
        order_id=order.order_id,
        client_order_id=order.client_order_id,
        account_id=order.account_id,
        stock_symbol=stock_symbol,
        order_type=order.order_type,
        order_kind=order.order_kind,
        quantity=order.quantity,
        filled_quantity=order.filled_quantity,
        remaining_quantity=order.quantity - order.filled_quantity,
        order_price=order.order_price,
        status=order.status,
        reject_reason=order.reject_reason,
        order_date=order.order_date,
        matched_at=order.matched_at,
    )


def list_account_orders(
    db: Session,
    customer: Customer,
    account_id: int,
    status: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> Page[OrderResponse]:
    """Retrieve paginated orders for an investment account."""
    account = verify_account_ownership(db, customer, account_id)
    items, total = get_orders_by_account(
        db=db,
        account_id=account.account_id,
        status=status,
        page=page,
        page_size=page_size,
    )
    return Page(
        items=[build_order_response(o) for o in items],
        page=page,
        page_size=page_size,
        total=total,
    )


def list_account_transactions(
    db: Session,
    customer: Customer,
    account_id: int,
    page: int = 1,
    page_size: int = 20,
) -> Page[TransactionResponse]:
    """Retrieve paginated trade transactions for an investment account."""
    account = verify_account_ownership(db, customer, account_id)
    items, total = get_transactions_by_account(
        db=db,
        account_id=account.account_id,
        page=page,
        page_size=page_size,
    )
    return Page(
        items=[
            TransactionResponse(
                transaction_id=t.transaction_id,
                order_id=t.order_id,
                account_id=t.account_id,
                stock_symbol=t.stock.stock_symbol if t.stock else "",
                transaction_type=t.transaction_type,
                quantity=t.quantity,
                price=t.price,
                total_amount=t.total_amount,
                transaction_fee=t.transaction_fee,
                tax_amount=t.tax_amount,
                net_amount=t.net_amount,
                transaction_date=t.transaction_date,
                settlement_date=t.settlement_date,
            )
            for t in items
        ],
        page=page,
        page_size=page_size,
        total=total,
    )
