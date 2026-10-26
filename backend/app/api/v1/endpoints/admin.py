"""Owner: TV1 - Phuoc.

Comprehensive Admin Portal endpoints:
- Administrative Dashboard & System KPI stats
- Full CRUD operations on Customers (with Cascade Delete)
- Full CRUD operations on Investment Accounts
- Full CRUD operations on Listed Stocks
- Full CRUD & Status Interventions on Stock Orders
- Full CRUD operations on Transactions
- Full CRUD operations on Portfolios
- Full CRUD operations on Stock Price History (OHLCV)
- Full CRUD & Broadcast operations on Notifications
- Full CRUD operations on Watchlists
"""

import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.api.deps import CurrentAdminDep, get_db
from app.core.errors import ConflictException, NotFoundException, ValidationException
from app.core.security import get_password_hash
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.models.notification import Notification
from app.models.portfolio import Portfolio
from app.models.stock import Stock
from app.models.stock_order import StockOrder
from app.models.stock_price_history import StockPriceHistory
from app.models.transaction import Transaction
from app.models.watchlist import Watchlist
from app.schemas.admin import (
    AdminAccountCreate,
    AdminAccountResponse,
    AdminAccountUpdate,
    AdminCustomerCreate,
    AdminCustomerDetailResponse,
    AdminCustomerResponse,
    AdminCustomerUpdate,
    AdminDashboardKPIs,
    AdminDashboardResponse,
    AdminNotificationCreate,
    AdminNotificationResponse,
    AdminOrderResponse,
    AdminOrderUpdate,
    AdminPage,
    AdminPortfolioCreate,
    AdminPortfolioResponse,
    AdminPortfolioUpdate,
    AdminPriceHistoryCreate,
    AdminPriceHistoryResponse,
    AdminPriceHistoryUpdate,
    AdminStockCreate,
    AdminStockResponse,
    AdminStockUpdate,
    AdminTransactionCreate,
    AdminTransactionResponse,
    AdminWatchlistCreate,
    AdminWatchlistResponse,
)

router = APIRouter()


def _fmt(val: Decimal | float | int | None) -> str:
    """Format numeric values as 2-decimal strings."""
    if val is None:
        return "0.00"
    return f"{Decimal(str(val)):.2f}"


# =====================================================================
# 0. DASHBOARD SUMMARY
# =====================================================================


@router.get("/dashboard", response_model=AdminDashboardResponse)
def get_dashboard(
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminDashboardResponse:
    """Consolidated KPI overview of customers, accounts, stocks, orders, and trading."""
    # 1. Customers
    total_customers = db.query(func.count(Customer.customer_id)).scalar() or 0
    active_customers = (
        db.query(func.count(Customer.customer_id)).filter(Customer.status == "ACTIVE").scalar() or 0
    )
    locked_customers = (
        db.query(func.count(Customer.customer_id)).filter(Customer.status == "LOCKED").scalar() or 0
    )
    admin_count = (
        db.query(func.count(Customer.customer_id)).filter(Customer.role == "ADMIN").scalar() or 0
    )

    # 2. Accounts
    total_accounts = db.query(func.count(InvestmentAccount.account_id)).scalar() or 0
    active_accounts = (
        db.query(func.count(InvestmentAccount.account_id))
        .filter(InvestmentAccount.status == "ACTIVE")
        .scalar()
        or 0
    )
    suspended_accounts = (
        db.query(func.count(InvestmentAccount.account_id))
        .filter(InvestmentAccount.status == "SUSPENDED")
        .scalar()
        or 0
    )
    total_cash = db.query(func.sum(InvestmentAccount.cash_balance)).scalar() or Decimal("0.00")
    total_asset = db.query(func.sum(InvestmentAccount.total_asset_value)).scalar() or Decimal(
        "0.00"
    )

    # 3. Stocks
    total_stocks = db.query(func.count(Stock.stock_id)).scalar() or 0
    active_stocks = (
        db.query(func.count(Stock.stock_id)).filter(Stock.status == "ACTIVE").scalar() or 0
    )
    halted_stocks = (
        db.query(func.count(Stock.stock_id)).filter(Stock.status == "HALTED").scalar() or 0
    )

    # 4. Orders Today
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    total_orders_today = (
        db.query(func.count(StockOrder.order_id))
        .filter(StockOrder.order_date >= today_start)
        .scalar()
        or 0
    )
    pending_orders = (
        db.query(func.count(StockOrder.order_id))
        .filter(StockOrder.order_date >= today_start, StockOrder.status == "PENDING")
        .scalar()
        or 0
    )
    completed_orders = (
        db.query(func.count(StockOrder.order_id))
        .filter(StockOrder.order_date >= today_start, StockOrder.status == "COMPLETED")
        .scalar()
        or 0
    )
    cancelled_orders = (
        db.query(func.count(StockOrder.order_id))
        .filter(StockOrder.order_date >= today_start, StockOrder.status == "CANCELLED")
        .scalar()
        or 0
    )

    # 5. Transactions Today
    total_txn_today = (
        db.query(func.count(Transaction.transaction_id))
        .filter(Transaction.transaction_date >= today_start)
        .scalar()
        or 0
    )
    total_volume_today = (
        db.query(func.sum(Transaction.quantity))
        .filter(Transaction.transaction_date >= today_start)
        .scalar()
        or 0
    )
    total_value_today = db.query(func.sum(Transaction.net_amount)).filter(
        Transaction.transaction_date >= today_start
    ).scalar() or Decimal("0.00")

    # Recent Orders (5 latest)
    recent_order_rows = db.query(StockOrder).order_by(StockOrder.order_date.desc()).limit(5).all()
    recent_orders: list[AdminOrderResponse] = []
    for o in recent_order_rows:
        recent_orders.append(
            AdminOrderResponse(
                order_id=o.order_id,
                account_id=o.account_id,
                account_number=o.account.account_number if o.account else "",
                customer_name=o.account.customer.full_name
                if o.account and o.account.customer
                else "",
                stock_id=o.stock_id,
                stock_symbol=o.stock.stock_symbol if o.stock else "",
                client_order_id=str(o.client_order_id),
                order_type=o.order_type,
                order_kind=o.order_kind,
                quantity=o.quantity,
                filled_quantity=o.filled_quantity,
                remaining_quantity=o.quantity - o.filled_quantity,
                order_price=_fmt(o.order_price),
                order_date=o.order_date,
                matched_at=o.matched_at,
                status=o.status,
                reject_reason=o.reject_reason,
            )
        )

    # Recent Transactions (5 latest)
    recent_txn_rows = (
        db.query(Transaction).order_by(Transaction.transaction_date.desc()).limit(5).all()
    )
    recent_transactions: list[AdminTransactionResponse] = []
    for t in recent_txn_rows:
        recent_transactions.append(
            AdminTransactionResponse(
                transaction_id=t.transaction_id,
                order_id=t.order_id,
                account_id=t.account_id,
                account_number=t.account.account_number if t.account else "",
                stock_id=t.stock_id,
                stock_symbol=t.stock.stock_symbol if t.stock else "",
                transaction_type=t.transaction_type,
                quantity=t.quantity,
                price=_fmt(t.price),
                total_amount=_fmt(t.total_amount),
                transaction_fee=_fmt(t.transaction_fee),
                tax_amount=_fmt(t.tax_amount),
                net_amount=_fmt(t.net_amount),
                transaction_date=t.transaction_date,
                settlement_date=t.settlement_date,
            )
        )

    # Top Stocks (by total_volume)
    top_stock_rows = db.query(Stock).order_by(Stock.total_volume.desc()).limit(5).all()
    top_stocks: list[AdminStockResponse] = []
    for s in top_stock_rows:
        p_change = s.current_price - s.reference_price
        pct_change = (
            (p_change / s.reference_price * 100) if s.reference_price > 0 else Decimal("0.00")
        )
        top_stocks.append(
            AdminStockResponse(
                stock_id=s.stock_id,
                stock_symbol=s.stock_symbol,
                company_name=s.company_name,
                exchange=s.exchange,
                industry=s.industry,
                listed_shares=s.listed_shares,
                current_price=_fmt(s.current_price),
                reference_price=_fmt(s.reference_price),
                ceiling_price=_fmt(s.ceiling_price),
                floor_price=_fmt(s.floor_price),
                price_change=_fmt(p_change),
                change_percent=_fmt(pct_change),
                total_volume=s.total_volume,
                status=s.status,
                updated_at=s.updated_at,
            )
        )

    return AdminDashboardResponse(
        kpis=AdminDashboardKPIs(
            total_customers=total_customers,
            active_customers=active_customers,
            locked_customers=locked_customers,
            admin_count=admin_count,
            total_accounts=total_accounts,
            active_accounts=active_accounts,
            suspended_accounts=suspended_accounts,
            total_cash_balance=_fmt(total_cash),
            total_asset_value=_fmt(total_asset),
            total_stocks=total_stocks,
            active_stocks=active_stocks,
            halted_stocks=halted_stocks,
            total_orders_today=total_orders_today,
            pending_orders=pending_orders,
            completed_orders=completed_orders,
            cancelled_orders=cancelled_orders,
            total_transactions_today=total_txn_today,
            total_trading_volume_today=total_volume_today,
            total_trading_value_today=_fmt(total_value_today),
        ),
        recent_orders=recent_orders,
        recent_transactions=recent_transactions,
        top_stocks=top_stocks,
        system_status="OPERATIONAL",
    )


# =====================================================================
# 1. CUSTOMERS CRUD
# =====================================================================


@router.get("/customers", response_model=AdminPage[AdminCustomerResponse])
def list_customers(
    _: CurrentAdminDep,
    q: str | None = Query(default=None, description="Search by name, email, or phone"),
    role: str | None = Query(default=None, description="Filter by role: CUSTOMER or ADMIN"),
    status: str | None = Query(
        default=None, description="Filter by status: ACTIVE, LOCKED, PENDING, CLOSED"
    ),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminCustomerResponse]:
    """Retrieve paginated list of customers with search and filter capabilities."""
    query = db.query(Customer)
    if q:
        query = query.filter(
            or_(
                Customer.full_name.ilike(f"%{q}%"),
                Customer.email.ilike(f"%{q}%"),
                Customer.phone_number.ilike(f"%{q}%"),
            )
        )
    if role:
        query = query.filter(Customer.role == role.upper())
    if status:
        query = query.filter(Customer.status == status.upper())

    total = query.count()
    customers = (
        query.order_by(Customer.customer_id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminCustomerResponse(
            customer_id=c.customer_id,
            full_name=c.full_name,
            email=c.email,
            phone_number=c.phone_number,
            role=c.role,
            status=c.status,
            date_of_birth=c.date_of_birth,
            id_card_number=c.id_card_number,
            address=c.address,
            avatar_url=c.avatar_url,
            created_at=c.created_at,
            updated_at=c.updated_at,
            accounts_count=len(c.accounts),
        )
        for c in customers
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/customers", response_model=AdminCustomerResponse, status_code=status.HTTP_201_CREATED
)
def create_customer(
    payload: AdminCustomerCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminCustomerResponse:
    """Create a new customer or administrator account."""
    if db.query(Customer).filter(Customer.email == payload.email).first():
        raise ConflictException(
            message="Email đã được đăng ký trong hệ thống.", code="DUPLICATE_EMAIL"
        )
    if db.query(Customer).filter(Customer.phone_number == payload.phone_number).first():
        raise ConflictException(
            message="Số điện thoại đã được đăng ký trong hệ thống.", code="DUPLICATE_PHONE"
        )
    if (
        payload.id_card_number
        and db.query(Customer).filter(Customer.id_card_number == payload.id_card_number).first()
    ):
        raise ConflictException(message="Số CMND/CCCD đã tồn tại.", code="DUPLICATE_ID_CARD")

    password_hash = get_password_hash(payload.password)
    customer = Customer(
        full_name=payload.full_name,
        email=payload.email,
        phone_number=payload.phone_number,
        password_hash=password_hash,
        role=payload.role.upper(),
        status=payload.status.upper(),
        date_of_birth=payload.date_of_birth,
        id_card_number=payload.id_card_number,
        address=payload.address,
        avatar_url=payload.avatar_url,
    )
    db.add(customer)
    db.flush()

    # Automatically create default CASH investment account
    acc_count = db.query(func.count(InvestmentAccount.account_id)).scalar() or 0
    acc_num = f"068C{acc_count + 1:06d}"
    account = InvestmentAccount(
        customer_id=customer.customer_id,
        account_number=acc_num,
        account_type="CASH",
        cash_balance=payload.initial_cash_balance,
        total_asset_value=payload.initial_cash_balance,
        status="ACTIVE",
    )
    db.add(account)
    db.commit()
    db.refresh(customer)

    return AdminCustomerResponse(
        customer_id=customer.customer_id,
        full_name=customer.full_name,
        email=customer.email,
        phone_number=customer.phone_number,
        role=customer.role,
        status=customer.status,
        date_of_birth=customer.date_of_birth,
        id_card_number=customer.id_card_number,
        address=customer.address,
        avatar_url=customer.avatar_url,
        created_at=customer.created_at,
        updated_at=customer.updated_at,
        accounts_count=1,
    )


@router.get("/customers/{customer_id}", response_model=AdminCustomerDetailResponse)
def get_customer_detail(
    customer_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminCustomerDetailResponse:
    """Retrieve full details of a customer including all trading accounts."""
    customer = db.query(Customer).filter(Customer.customer_id == customer_id).first()
    if customer is None:
        raise NotFoundException(message="Không tìm thấy khách hàng yêu cầu.")

    accounts = [
        AdminAccountResponse(
            account_id=a.account_id,
            customer_id=a.customer_id,
            customer_name=customer.full_name,
            customer_email=customer.email,
            account_number=a.account_number,
            account_type=a.account_type,
            cash_balance=_fmt(a.cash_balance),
            blocked_balance=_fmt(a.blocked_balance),
            total_asset_value=_fmt(a.total_asset_value),
            margin_limit=_fmt(a.margin_limit),
            status=a.status,
            created_at=a.created_at,
            updated_at=a.updated_at,
        )
        for a in customer.accounts
    ]

    return AdminCustomerDetailResponse(
        customer_id=customer.customer_id,
        full_name=customer.full_name,
        email=customer.email,
        phone_number=customer.phone_number,
        role=customer.role,
        status=customer.status,
        date_of_birth=customer.date_of_birth,
        id_card_number=customer.id_card_number,
        address=customer.address,
        avatar_url=customer.avatar_url,
        created_at=customer.created_at,
        updated_at=customer.updated_at,
        accounts_count=len(customer.accounts),
        accounts=accounts,
    )


@router.put("/customers/{customer_id}", response_model=AdminCustomerResponse)
def update_customer(
    customer_id: int,
    payload: AdminCustomerUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminCustomerResponse:
    """Update customer details, change status (ACTIVE/LOCKED), role, or reset password."""
    customer = db.query(Customer).filter(Customer.customer_id == customer_id).first()
    if customer is None:
        raise NotFoundException(message="Không tìm thấy khách hàng yêu cầu.")

    if payload.email and payload.email != customer.email:
        if db.query(Customer).filter(Customer.email == payload.email).first():
            raise ConflictException(
                message="Email đã được sử dụng bởi người dùng khác.", code="DUPLICATE_EMAIL"
            )
        customer.email = payload.email

    if payload.phone_number and payload.phone_number != customer.phone_number:
        if db.query(Customer).filter(Customer.phone_number == payload.phone_number).first():
            raise ConflictException(
                message="Số điện thoại đã được sử dụng bởi người dùng khác.", code="DUPLICATE_PHONE"
            )
        customer.phone_number = payload.phone_number

    if payload.id_card_number and payload.id_card_number != customer.id_card_number:
        if db.query(Customer).filter(Customer.id_card_number == payload.id_card_number).first():
            raise ConflictException(message="Số CMND/CCCD đã tồn tại.", code="DUPLICATE_ID_CARD")
        customer.id_card_number = payload.id_card_number

    if payload.full_name is not None:
        customer.full_name = payload.full_name
    if payload.role is not None:
        customer.role = payload.role.upper()
    if payload.status is not None:
        customer.status = payload.status.upper()
    if payload.date_of_birth is not None:
        customer.date_of_birth = payload.date_of_birth
    if payload.address is not None:
        customer.address = payload.address
    if payload.avatar_url is not None:
        customer.avatar_url = payload.avatar_url
    if payload.password:
        customer.password_hash = get_password_hash(payload.password)

    db.commit()
    db.refresh(customer)

    return AdminCustomerResponse(
        customer_id=customer.customer_id,
        full_name=customer.full_name,
        email=customer.email,
        phone_number=customer.phone_number,
        role=customer.role,
        status=customer.status,
        date_of_birth=customer.date_of_birth,
        id_card_number=customer.id_card_number,
        address=customer.address,
        avatar_url=customer.avatar_url,
        created_at=customer.created_at,
        updated_at=customer.updated_at,
        accounts_count=len(customer.accounts),
    )


@router.delete("/customers/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_customer(
    customer_id: int,
    current_admin: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Permanently delete customer account and cascade delete all related data."""
    if current_admin.customer_id == customer_id:
        raise ValidationException(
            message="Quản trị viên không thể tự xóa tài khoản của chính mình.",
            code="CANNOT_DELETE_SELF",
        )

    customer = db.query(Customer).filter(Customer.customer_id == customer_id).first()
    if customer is None:
        raise NotFoundException(message="Không tìm thấy khách hàng cần xóa.")

    db.delete(customer)
    db.commit()


# =====================================================================
# 2. INVESTMENT ACCOUNTS CRUD
# =====================================================================


@router.get("/accounts", response_model=AdminPage[AdminAccountResponse])
def list_accounts(
    _: CurrentAdminDep,
    q: str | None = Query(default=None, description="Search by account number or customer name"),
    customer_id: int | None = Query(default=None),
    account_type: str | None = Query(default=None, description="CASH or MARGIN"),
    status: str | None = Query(default=None, description="ACTIVE, SUSPENDED, CLOSED"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminAccountResponse]:
    """Retrieve paginated list of all investment accounts."""
    query = db.query(InvestmentAccount).join(Customer)
    if q:
        query = query.filter(
            or_(
                InvestmentAccount.account_number.ilike(f"%{q}%"),
                Customer.full_name.ilike(f"%{q}%"),
                Customer.email.ilike(f"%{q}%"),
            )
        )
    if customer_id:
        query = query.filter(InvestmentAccount.customer_id == customer_id)
    if account_type:
        query = query.filter(InvestmentAccount.account_type == account_type.upper())
    if status:
        query = query.filter(InvestmentAccount.status == status.upper())

    total = query.count()
    accounts = (
        query.order_by(InvestmentAccount.account_id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminAccountResponse(
            account_id=a.account_id,
            customer_id=a.customer_id,
            customer_name=a.customer.full_name if a.customer else "",
            customer_email=a.customer.email if a.customer else "",
            account_number=a.account_number,
            account_type=a.account_type,
            cash_balance=_fmt(a.cash_balance),
            blocked_balance=_fmt(a.blocked_balance),
            total_asset_value=_fmt(a.total_asset_value),
            margin_limit=_fmt(a.margin_limit),
            status=a.status,
            created_at=a.created_at,
            updated_at=a.updated_at,
        )
        for a in accounts
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post("/accounts", response_model=AdminAccountResponse, status_code=status.HTTP_201_CREATED)
def create_account(
    payload: AdminAccountCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminAccountResponse:
    """Create a new investment account for a customer."""
    customer = db.query(Customer).filter(Customer.customer_id == payload.customer_id).first()
    if customer is None:
        raise NotFoundException(message="Không tìm thấy khách hàng để mở tài khoản.")

    if payload.account_number:
        if (
            db.query(InvestmentAccount)
            .filter(InvestmentAccount.account_number == payload.account_number)
            .first()
        ):
            raise ConflictException(
                message="Số tài khoản đã tồn tại.", code="DUPLICATE_ACCOUNT_NUMBER"
            )
        account_number = payload.account_number
    else:
        prefix = "068M" if payload.account_type.upper() == "MARGIN" else "068C"
        acc_count = db.query(func.count(InvestmentAccount.account_id)).scalar() or 0
        account_number = f"{prefix}{acc_count + 1:06d}"

    account = InvestmentAccount(
        customer_id=payload.customer_id,
        account_number=account_number,
        account_type=payload.account_type.upper(),
        cash_balance=payload.cash_balance,
        blocked_balance=Decimal("0.00"),
        total_asset_value=payload.cash_balance,
        margin_limit=payload.margin_limit,
        status=payload.status.upper(),
    )
    db.add(account)
    db.commit()
    db.refresh(account)

    return AdminAccountResponse(
        account_id=account.account_id,
        customer_id=account.customer_id,
        customer_name=customer.full_name,
        customer_email=customer.email,
        account_number=account.account_number,
        account_type=account.account_type,
        cash_balance=_fmt(account.cash_balance),
        blocked_balance=_fmt(account.blocked_balance),
        total_asset_value=_fmt(account.total_asset_value),
        margin_limit=_fmt(account.margin_limit),
        status=account.status,
        created_at=account.created_at,
        updated_at=account.updated_at,
    )


@router.get("/accounts/{account_id}", response_model=AdminAccountResponse)
def get_account(
    account_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminAccountResponse:
    """Get single investment account details."""
    account = db.query(InvestmentAccount).filter(InvestmentAccount.account_id == account_id).first()
    if account is None:
        raise NotFoundException(message="Không tìm thấy tài khoản đầu tư.")

    return AdminAccountResponse(
        account_id=account.account_id,
        customer_id=account.customer_id,
        customer_name=account.customer.full_name if account.customer else "",
        customer_email=account.customer.email if account.customer else "",
        account_number=account.account_number,
        account_type=account.account_type,
        cash_balance=_fmt(account.cash_balance),
        blocked_balance=_fmt(account.blocked_balance),
        total_asset_value=_fmt(account.total_asset_value),
        margin_limit=_fmt(account.margin_limit),
        status=account.status,
        created_at=account.created_at,
        updated_at=account.updated_at,
    )


@router.put("/accounts/{account_id}", response_model=AdminAccountResponse)
def update_account(
    account_id: int,
    payload: AdminAccountUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminAccountResponse:
    """Adjust account balances, type, or change status (ACTIVE/SUSPENDED/CLOSED)."""
    account = db.query(InvestmentAccount).filter(InvestmentAccount.account_id == account_id).first()
    if account is None:
        raise NotFoundException(message="Không tìm thấy tài khoản đầu tư.")

    if payload.account_type is not None:
        account.account_type = payload.account_type.upper()
    if payload.cash_balance is not None:
        account.cash_balance = payload.cash_balance
    if payload.blocked_balance is not None:
        account.blocked_balance = payload.blocked_balance
    if payload.total_asset_value is not None:
        account.total_asset_value = payload.total_asset_value
    if payload.margin_limit is not None:
        account.margin_limit = payload.margin_limit
    if payload.status is not None:
        account.status = payload.status.upper()

    db.commit()
    db.refresh(account)

    return AdminAccountResponse(
        account_id=account.account_id,
        customer_id=account.customer_id,
        customer_name=account.customer.full_name if account.customer else "",
        customer_email=account.customer.email if account.customer else "",
        account_number=account.account_number,
        account_type=account.account_type,
        cash_balance=_fmt(account.cash_balance),
        blocked_balance=_fmt(account.blocked_balance),
        total_asset_value=_fmt(account.total_asset_value),
        margin_limit=_fmt(account.margin_limit),
        status=account.status,
        created_at=account.created_at,
        updated_at=account.updated_at,
    )


@router.delete("/accounts/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Delete an investment account and cascade related orders and portfolios."""
    account = db.query(InvestmentAccount).filter(InvestmentAccount.account_id == account_id).first()
    if account is None:
        raise NotFoundException(message="Không tìm thấy tài khoản cần xóa.")

    db.delete(account)
    db.commit()


# =====================================================================
# 3. STOCKS CRUD
# =====================================================================


@router.get("/stocks", response_model=AdminPage[AdminStockResponse])
def list_stocks(
    _: CurrentAdminDep,
    q: str | None = Query(default=None, description="Search by symbol or company name"),
    exchange: str | None = Query(default=None, description="HOSE, HNX, UPCOM"),
    status: str | None = Query(default=None, description="ACTIVE, HALTED, DELISTED"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
) -> AdminPage[AdminStockResponse]:
    """Retrieve all listed stocks with filter by exchange and status."""
    query = db.query(Stock)
    if q:
        query = query.filter(
            or_(
                Stock.stock_symbol.ilike(f"%{q}%"),
                Stock.company_name.ilike(f"%{q}%"),
            )
        )
    if exchange:
        query = query.filter(Stock.exchange == exchange.upper())
    if status:
        query = query.filter(Stock.status == status.upper())

    total = query.count()
    stocks = (
        query.order_by(Stock.stock_symbol.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = []
    for s in stocks:
        p_change = s.current_price - s.reference_price
        pct_change = (
            (p_change / s.reference_price * 100) if s.reference_price > 0 else Decimal("0.00")
        )
        items.append(
            AdminStockResponse(
                stock_id=s.stock_id,
                stock_symbol=s.stock_symbol,
                company_name=s.company_name,
                exchange=s.exchange,
                industry=s.industry,
                listed_shares=s.listed_shares,
                current_price=_fmt(s.current_price),
                reference_price=_fmt(s.reference_price),
                ceiling_price=_fmt(s.ceiling_price),
                floor_price=_fmt(s.floor_price),
                price_change=_fmt(p_change),
                change_percent=_fmt(pct_change),
                total_volume=s.total_volume,
                status=s.status,
                updated_at=s.updated_at,
            )
        )

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post("/stocks", response_model=AdminStockResponse, status_code=status.HTTP_201_CREATED)
def create_stock(
    payload: AdminStockCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminStockResponse:
    """Create a new listed stock symbol."""
    sym = payload.stock_symbol.upper().strip()
    if db.query(Stock).filter(Stock.stock_symbol == sym).first():
        raise ConflictException(
            message=f"Mã cổ phiếu {sym} đã tồn tại trên sàn.", code="DUPLICATE_STOCK_SYMBOL"
        )

    # Band calculation if ceiling/floor omitted
    band = (
        Decimal("0.07")
        if payload.exchange == "HOSE"
        else (Decimal("0.10") if payload.exchange == "HNX" else Decimal("0.15"))
    )
    ceiling = payload.ceiling_price or (payload.reference_price * (1 + band)).quantize(
        Decimal("100")
    )
    floor = payload.floor_price or (payload.reference_price * (1 - band)).quantize(Decimal("100"))
    current = payload.current_price or payload.reference_price

    stock = Stock(
        stock_symbol=sym,
        company_name=payload.company_name,
        exchange=payload.exchange.upper(),
        industry=payload.industry,
        listed_shares=payload.listed_shares,
        current_price=current,
        reference_price=payload.reference_price,
        ceiling_price=ceiling,
        floor_price=floor,
        total_volume=0,
        status=payload.status.upper(),
    )
    db.add(stock)
    db.commit()
    db.refresh(stock)

    p_change = stock.current_price - stock.reference_price
    pct_change = (
        (p_change / stock.reference_price * 100) if stock.reference_price > 0 else Decimal("0.00")
    )

    return AdminStockResponse(
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        exchange=stock.exchange,
        industry=stock.industry,
        listed_shares=stock.listed_shares,
        current_price=_fmt(stock.current_price),
        reference_price=_fmt(stock.reference_price),
        ceiling_price=_fmt(stock.ceiling_price),
        floor_price=_fmt(stock.floor_price),
        price_change=_fmt(p_change),
        change_percent=_fmt(pct_change),
        total_volume=stock.total_volume,
        status=stock.status,
        updated_at=stock.updated_at,
    )


@router.get("/stocks/{stock_id}", response_model=AdminStockResponse)
def get_stock(
    stock_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminStockResponse:
    """Get single stock details."""
    stock = db.query(Stock).filter(Stock.stock_id == stock_id).first()
    if stock is None:
        raise NotFoundException(message="Không tìm thấy mã cổ phiếu.")

    p_change = stock.current_price - stock.reference_price
    pct_change = (
        (p_change / stock.reference_price * 100) if stock.reference_price > 0 else Decimal("0.00")
    )

    return AdminStockResponse(
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        exchange=stock.exchange,
        industry=stock.industry,
        listed_shares=stock.listed_shares,
        current_price=_fmt(stock.current_price),
        reference_price=_fmt(stock.reference_price),
        ceiling_price=_fmt(stock.ceiling_price),
        floor_price=_fmt(stock.floor_price),
        price_change=_fmt(p_change),
        change_percent=_fmt(pct_change),
        total_volume=stock.total_volume,
        status=stock.status,
        updated_at=stock.updated_at,
    )


@router.put("/stocks/{stock_id}", response_model=AdminStockResponse)
def update_stock(
    stock_id: int,
    payload: AdminStockUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminStockResponse:
    """Update stock enterprise details, pricing, trading volume, or status."""
    stock = db.query(Stock).filter(Stock.stock_id == stock_id).first()
    if stock is None:
        raise NotFoundException(message="Không tìm thấy mã cổ phiếu.")

    if payload.company_name is not None:
        stock.company_name = payload.company_name
    if payload.exchange is not None:
        stock.exchange = payload.exchange.upper()
    if payload.industry is not None:
        stock.industry = payload.industry
    if payload.listed_shares is not None:
        stock.listed_shares = payload.listed_shares
    if payload.current_price is not None:
        stock.current_price = payload.current_price
    if payload.reference_price is not None:
        stock.reference_price = payload.reference_price
    if payload.ceiling_price is not None:
        stock.ceiling_price = payload.ceiling_price
    if payload.floor_price is not None:
        stock.floor_price = payload.floor_price
    if payload.total_volume is not None:
        stock.total_volume = payload.total_volume
    if payload.status is not None:
        stock.status = payload.status.upper()

    db.commit()
    db.refresh(stock)

    p_change = stock.current_price - stock.reference_price
    pct_change = (
        (p_change / stock.reference_price * 100) if stock.reference_price > 0 else Decimal("0.00")
    )

    return AdminStockResponse(
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        exchange=stock.exchange,
        industry=stock.industry,
        listed_shares=stock.listed_shares,
        current_price=_fmt(stock.current_price),
        reference_price=_fmt(stock.reference_price),
        ceiling_price=_fmt(stock.ceiling_price),
        floor_price=_fmt(stock.floor_price),
        price_change=_fmt(p_change),
        change_percent=_fmt(pct_change),
        total_volume=stock.total_volume,
        status=stock.status,
        updated_at=stock.updated_at,
    )


@router.delete("/stocks/{stock_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_stock(
    stock_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Delete a stock and cascade price history / watchlists."""
    stock = db.query(Stock).filter(Stock.stock_id == stock_id).first()
    if stock is None:
        raise NotFoundException(message="Không tìm thấy mã cổ phiếu cần xóa.")

    # Check active orders
    active_orders = (
        db.query(StockOrder)
        .filter(StockOrder.stock_id == stock_id, StockOrder.status.in_(["PENDING", "PARTIAL"]))
        .first()
    )
    if active_orders:
        raise ConflictException(
            message=(
                "Không thể xóa cổ phiếu đang có lệnh chờ khớp trên sàn. "
                "Vui lòng hủy các lệnh trước."
            ),
            code="STOCK_HAS_ACTIVE_ORDERS",
        )

    db.delete(stock)
    db.commit()


# =====================================================================
# 4. STOCK ORDERS CRUD & INTERVENTION
# =====================================================================


@router.get("/orders", response_model=AdminPage[AdminOrderResponse])
def list_orders(
    _: CurrentAdminDep,
    account_id: int | None = Query(default=None),
    stock_symbol: str | None = Query(default=None),
    status: str | None = Query(default=None),
    order_type: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminOrderResponse]:
    """Retrieve all orders placed across all accounts on the exchange."""
    query = db.query(StockOrder).join(Stock).join(InvestmentAccount).join(Customer)
    if account_id:
        query = query.filter(StockOrder.account_id == account_id)
    if stock_symbol:
        query = query.filter(Stock.stock_symbol == stock_symbol.upper().strip())
    if status:
        query = query.filter(StockOrder.status == status.upper())
    if order_type:
        query = query.filter(StockOrder.order_type == order_type.upper())

    total = query.count()
    orders = (
        query.order_by(StockOrder.order_date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminOrderResponse(
            order_id=o.order_id,
            account_id=o.account_id,
            account_number=o.account.account_number if o.account else "",
            customer_name=o.account.customer.full_name if o.account and o.account.customer else "",
            stock_id=o.stock_id,
            stock_symbol=o.stock.stock_symbol if o.stock else "",
            client_order_id=str(o.client_order_id),
            order_type=o.order_type,
            order_kind=o.order_kind,
            quantity=o.quantity,
            filled_quantity=o.filled_quantity,
            remaining_quantity=o.quantity - o.filled_quantity,
            order_price=_fmt(o.order_price),
            order_date=o.order_date,
            matched_at=o.matched_at,
            status=o.status,
            reject_reason=o.reject_reason,
        )
        for o in orders
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.get("/orders/{order_id}", response_model=AdminOrderResponse)
def get_order(
    order_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminOrderResponse:
    """Retrieve single order details."""
    order = db.query(StockOrder).filter(StockOrder.order_id == order_id).first()
    if order is None:
        raise NotFoundException(message="Không tìm thấy lệnh đặt.")

    return AdminOrderResponse(
        order_id=order.order_id,
        account_id=order.account_id,
        account_number=order.account.account_number if order.account else "",
        customer_name=order.account.customer.full_name
        if order.account and order.account.customer
        else "",
        stock_id=order.stock_id,
        stock_symbol=order.stock.stock_symbol if order.stock else "",
        client_order_id=str(order.client_order_id),
        order_type=order.order_type,
        order_kind=order.order_kind,
        quantity=order.quantity,
        filled_quantity=order.filled_quantity,
        remaining_quantity=order.quantity - order.filled_quantity,
        order_price=_fmt(order.order_price),
        order_date=order.order_date,
        matched_at=order.matched_at,
        status=order.status,
        reject_reason=order.reject_reason,
    )


@router.put("/orders/{order_id}", response_model=AdminOrderResponse)
def update_order(
    order_id: int,
    payload: AdminOrderUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminOrderResponse:
    """Admin intervention: modify order status (e.g. force CANCELLED or COMPLETED) or quantities."""
    order = db.query(StockOrder).filter(StockOrder.order_id == order_id).first()
    if order is None:
        raise NotFoundException(message="Không tìm thấy lệnh đặt.")

    if payload.status is not None:
        order.status = payload.status.upper()
        if order.status == "COMPLETED" and order.matched_at is None:
            order.matched_at = datetime.now(timezone.utc)
    if payload.filled_quantity is not None:
        order.filled_quantity = payload.filled_quantity
    if payload.reject_reason is not None:
        order.reject_reason = payload.reject_reason

    db.commit()
    db.refresh(order)

    return AdminOrderResponse(
        order_id=order.order_id,
        account_id=order.account_id,
        account_number=order.account.account_number if order.account else "",
        customer_name=order.account.customer.full_name
        if order.account and order.account.customer
        else "",
        stock_id=order.stock_id,
        stock_symbol=order.stock.stock_symbol if order.stock else "",
        client_order_id=str(order.client_order_id),
        order_type=order.order_type,
        order_kind=order.order_kind,
        quantity=order.quantity,
        filled_quantity=order.filled_quantity,
        remaining_quantity=order.quantity - order.filled_quantity,
        order_price=_fmt(order.order_price),
        order_date=order.order_date,
        matched_at=order.matched_at,
        status=order.status,
        reject_reason=order.reject_reason,
    )


@router.delete("/orders/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_or_delete_order(
    order_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Admin intervention: delete or cancel order."""
    order = db.query(StockOrder).filter(StockOrder.order_id == order_id).first()
    if order is None:
        raise NotFoundException(message="Không tìm thấy lệnh cần xóa/hủy.")

    db.delete(order)
    db.commit()


# =====================================================================
# 5. TRANSACTIONS CRUD
# =====================================================================


@router.get("/transactions", response_model=AdminPage[AdminTransactionResponse])
def list_transactions(
    _: CurrentAdminDep,
    account_id: int | None = Query(default=None),
    stock_symbol: str | None = Query(default=None),
    transaction_type: str | None = Query(default=None, description="BUY or SELL"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminTransactionResponse]:
    """Retrieve paginated trade transactions executed across all accounts."""
    query = db.query(Transaction).join(Stock).join(InvestmentAccount)
    if account_id:
        query = query.filter(Transaction.account_id == account_id)
    if stock_symbol:
        query = query.filter(Stock.stock_symbol == stock_symbol.upper().strip())
    if transaction_type:
        query = query.filter(Transaction.transaction_type == transaction_type.upper())

    total = query.count()
    txns = (
        query.order_by(Transaction.transaction_date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminTransactionResponse(
            transaction_id=t.transaction_id,
            order_id=t.order_id,
            account_id=t.account_id,
            account_number=t.account.account_number if t.account else "",
            stock_id=t.stock_id,
            stock_symbol=t.stock.stock_symbol if t.stock else "",
            transaction_type=t.transaction_type,
            quantity=t.quantity,
            price=_fmt(t.price),
            total_amount=_fmt(t.total_amount),
            transaction_fee=_fmt(t.transaction_fee),
            tax_amount=_fmt(t.tax_amount),
            net_amount=_fmt(t.net_amount),
            transaction_date=t.transaction_date,
            settlement_date=t.settlement_date,
        )
        for t in txns
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/transactions", response_model=AdminTransactionResponse, status_code=status.HTTP_201_CREATED
)
def create_transaction(
    payload: AdminTransactionCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminTransactionResponse:
    """Manually insert a transaction adjustment."""
    account = (
        db.query(InvestmentAccount)
        .filter(InvestmentAccount.account_id == payload.account_id)
        .first()
    )
    if account is None:
        raise NotFoundException(message="Không tìm thấy tài khoản đầu tư.")

    stock = (
        db.query(Stock).filter(Stock.stock_symbol == payload.stock_symbol.upper().strip()).first()
    )
    if stock is None:
        raise NotFoundException(message=f"Không tìm thấy mã cổ phiếu {payload.stock_symbol}.")

    order_id = payload.order_id
    if not order_id:
        # Create an administrative placeholder order
        placeholder_order = StockOrder(
            account_id=account.account_id,
            stock_id=stock.stock_id,
            client_order_id=uuid.uuid4(),
            order_type=payload.transaction_type.upper(),
            order_kind="LO",
            quantity=payload.quantity,
            filled_quantity=payload.quantity,
            order_price=payload.price,
            status="COMPLETED",
            matched_at=datetime.now(timezone.utc),
        )
        db.add(placeholder_order)
        db.flush()
        order_id = placeholder_order.order_id

    total_amount = (payload.price * payload.quantity).quantize(Decimal("0.01"))
    if payload.transaction_type.upper() == "BUY":
        net_amount = total_amount + payload.transaction_fee
    else:
        net_amount = total_amount - payload.transaction_fee - payload.tax_amount

    txn = Transaction(
        order_id=order_id,
        account_id=payload.account_id,
        stock_id=stock.stock_id,
        transaction_type=payload.transaction_type.upper(),
        quantity=payload.quantity,
        price=payload.price,
        total_amount=total_amount,
        transaction_fee=payload.transaction_fee,
        tax_amount=payload.tax_amount,
        net_amount=net_amount,
        settlement_date=payload.settlement_date,
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)

    return AdminTransactionResponse(
        transaction_id=txn.transaction_id,
        order_id=txn.order_id,
        account_id=txn.account_id,
        account_number=account.account_number,
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        transaction_type=txn.transaction_type,
        quantity=txn.quantity,
        price=_fmt(txn.price),
        total_amount=_fmt(txn.total_amount),
        transaction_fee=_fmt(txn.transaction_fee),
        tax_amount=_fmt(txn.tax_amount),
        net_amount=_fmt(txn.net_amount),
        transaction_date=txn.transaction_date,
        settlement_date=txn.settlement_date,
    )


@router.delete("/transactions/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Delete a transaction record."""
    txn = db.query(Transaction).filter(Transaction.transaction_id == transaction_id).first()
    if txn is None:
        raise NotFoundException(message="Không tìm thấy giao dịch cần xóa.")

    db.delete(txn)
    db.commit()


# =====================================================================
# 6. PORTFOLIOS CRUD
# =====================================================================


@router.get("/portfolios", response_model=AdminPage[AdminPortfolioResponse])
def list_portfolios(
    _: CurrentAdminDep,
    account_id: int | None = Query(default=None),
    stock_symbol: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminPortfolioResponse]:
    """Retrieve portfolio holdings across accounts."""
    query = db.query(Portfolio).join(Stock).join(InvestmentAccount).join(Customer)
    if account_id:
        query = query.filter(Portfolio.account_id == account_id)
    if stock_symbol:
        query = query.filter(Stock.stock_symbol == stock_symbol.upper().strip())

    total = query.count()
    portfolios = (
        query.order_by(Portfolio.portfolio_id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = []
    for p in portfolios:
        cur_val = p.quantity * p.stock.current_price
        pl = cur_val - (p.quantity * p.average_price)
        pl_pct = (
            (pl / (p.quantity * p.average_price) * 100)
            if (p.quantity * p.average_price) > 0
            else Decimal("0.00")
        )
        items.append(
            AdminPortfolioResponse(
                portfolio_id=p.portfolio_id,
                account_id=p.account_id,
                account_number=p.account.account_number if p.account else "",
                customer_name=p.account.customer.full_name
                if p.account and p.account.customer
                else "",
                stock_id=p.stock_id,
                stock_symbol=p.stock.stock_symbol if p.stock else "",
                company_name=p.stock.company_name if p.stock else "",
                quantity=p.quantity,
                available_quantity=p.available_quantity,
                blocked_quantity=p.blocked_quantity,
                average_price=_fmt(p.average_price),
                current_value=_fmt(cur_val),
                profit_loss=_fmt(pl),
                profit_loss_percent=_fmt(pl_pct),
                updated_at=p.updated_at,
            )
        )

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/portfolios", response_model=AdminPortfolioResponse, status_code=status.HTTP_201_CREATED
)
def create_portfolio_holding(
    payload: AdminPortfolioCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminPortfolioResponse:
    """Manually add or initialize stock holdings for an account."""
    account = (
        db.query(InvestmentAccount)
        .filter(InvestmentAccount.account_id == payload.account_id)
        .first()
    )
    if account is None:
        raise NotFoundException(message="Không tìm thấy tài khoản đầu tư.")

    stock = (
        db.query(Stock).filter(Stock.stock_symbol == payload.stock_symbol.upper().strip()).first()
    )
    if stock is None:
        raise NotFoundException(message=f"Không tìm thấy mã cổ phiếu {payload.stock_symbol}.")

    existing = (
        db.query(Portfolio)
        .filter(Portfolio.account_id == payload.account_id, Portfolio.stock_id == stock.stock_id)
        .first()
    )
    if existing:
        raise ConflictException(
            message=f"Tài khoản đã nắm giữ mã {payload.stock_symbol}. Hãy dùng PUT để điều chỉnh.",
            code="PORTFOLIO_EXISTS",
        )

    cur_val = payload.quantity * stock.current_price
    pl = cur_val - (payload.quantity * payload.average_price)

    p = Portfolio(
        account_id=payload.account_id,
        stock_id=stock.stock_id,
        quantity=payload.quantity,
        available_quantity=payload.available_quantity,
        blocked_quantity=payload.blocked_quantity,
        average_price=payload.average_price,
        current_value=cur_val,
        profit_loss=pl,
    )
    db.add(p)
    db.commit()
    db.refresh(p)

    pl_pct = (
        (pl / (p.quantity * p.average_price) * 100)
        if (p.quantity * p.average_price) > 0
        else Decimal("0.00")
    )

    return AdminPortfolioResponse(
        portfolio_id=p.portfolio_id,
        account_id=p.account_id,
        account_number=account.account_number,
        customer_name=account.customer.full_name if account.customer else "",
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        quantity=p.quantity,
        available_quantity=p.available_quantity,
        blocked_quantity=p.blocked_quantity,
        average_price=_fmt(p.average_price),
        current_value=_fmt(cur_val),
        profit_loss=_fmt(pl),
        profit_loss_percent=_fmt(pl_pct),
        updated_at=p.updated_at,
    )


@router.put("/portfolios/{portfolio_id}", response_model=AdminPortfolioResponse)
def update_portfolio_holding(
    portfolio_id: int,
    payload: AdminPortfolioUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminPortfolioResponse:
    """Adjust share quantity, available quantity, or average price for an existing holding."""
    p = db.query(Portfolio).filter(Portfolio.portfolio_id == portfolio_id).first()
    if p is None:
        raise NotFoundException(message="Không tìm thấy danh mục nắm giữ.")

    if payload.quantity is not None:
        p.quantity = payload.quantity
    if payload.available_quantity is not None:
        p.available_quantity = payload.available_quantity
    if payload.blocked_quantity is not None:
        p.blocked_quantity = payload.blocked_quantity
    if payload.average_price is not None:
        p.average_price = payload.average_price

    cur_val = p.quantity * p.stock.current_price
    pl = cur_val - (p.quantity * p.average_price)
    p.current_value = cur_val
    p.profit_loss = pl

    db.commit()
    db.refresh(p)

    pl_pct = (
        (pl / (p.quantity * p.average_price) * 100)
        if (p.quantity * p.average_price) > 0
        else Decimal("0.00")
    )

    return AdminPortfolioResponse(
        portfolio_id=p.portfolio_id,
        account_id=p.account_id,
        account_number=p.account.account_number if p.account else "",
        customer_name=p.account.customer.full_name if p.account and p.account.customer else "",
        stock_id=p.stock_id,
        stock_symbol=p.stock.stock_symbol if p.stock else "",
        company_name=p.stock.company_name if p.stock else "",
        quantity=p.quantity,
        available_quantity=p.available_quantity,
        blocked_quantity=p.blocked_quantity,
        average_price=_fmt(p.average_price),
        current_value=_fmt(cur_val),
        profit_loss=_fmt(pl),
        profit_loss_percent=_fmt(pl_pct),
        updated_at=p.updated_at,
    )


@router.delete("/portfolios/{portfolio_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_portfolio_holding(
    portfolio_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Remove a stock holding from an account."""
    p = db.query(Portfolio).filter(Portfolio.portfolio_id == portfolio_id).first()
    if p is None:
        raise NotFoundException(message="Không tìm thấy danh mục cần xóa.")

    db.delete(p)
    db.commit()


# =====================================================================
# 7. STOCK PRICE HISTORY (OHLCV)
# =====================================================================


@router.get("/price-history", response_model=AdminPage[AdminPriceHistoryResponse])
def list_price_history(
    _: CurrentAdminDep,
    stock_id: int | None = Query(default=None),
    stock_symbol: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
) -> AdminPage[AdminPriceHistoryResponse]:
    """Retrieve daily candlestick OHLCV data."""
    query = db.query(StockPriceHistory).join(Stock)
    if stock_id:
        query = query.filter(StockPriceHistory.stock_id == stock_id)
    if stock_symbol:
        query = query.filter(Stock.stock_symbol == stock_symbol.upper().strip())
    if start_date:
        query = query.filter(StockPriceHistory.recorded_date >= start_date)
    if end_date:
        query = query.filter(StockPriceHistory.recorded_date <= end_date)

    total = query.count()
    candles = (
        query.order_by(StockPriceHistory.recorded_date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminPriceHistoryResponse(
            price_history_id=c.price_history_id,
            stock_id=c.stock_id,
            stock_symbol=c.stock.stock_symbol if c.stock else "",
            recorded_date=c.recorded_date,
            open_price=_fmt(c.open_price),
            close_price=_fmt(c.close_price),
            highest_price=_fmt(c.highest_price),
            lowest_price=_fmt(c.lowest_price),
            trading_volume=c.trading_volume,
            trading_value=_fmt(c.trading_value),
        )
        for c in candles
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/price-history", response_model=AdminPriceHistoryResponse, status_code=status.HTTP_201_CREATED
)
def create_price_history(
    payload: AdminPriceHistoryCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminPriceHistoryResponse:
    """Add a daily OHLCV candlestick record for a stock."""
    stock = None
    if payload.stock_id:
        stock = db.query(Stock).filter(Stock.stock_id == payload.stock_id).first()
    elif payload.stock_symbol:
        stock = (
            db.query(Stock)
            .filter(Stock.stock_symbol == payload.stock_symbol.upper().strip())
            .first()
        )

    if stock is None:
        raise NotFoundException(message="Không tìm thấy mã cổ phiếu hợp lệ.")

    # Check duplicate date
    if (
        db.query(StockPriceHistory)
        .filter(
            StockPriceHistory.stock_id == stock.stock_id,
            StockPriceHistory.recorded_date == payload.recorded_date,
        )
        .first()
    ):
        raise ConflictException(
            message=(
                f"Phiên giao dịch ngày {payload.recorded_date} của {stock.stock_symbol} đã tồn tại."
            ),
            code="CANDLE_EXISTS",
        )

    candle = StockPriceHistory(
        stock_id=stock.stock_id,
        recorded_date=payload.recorded_date,
        open_price=payload.open_price,
        close_price=payload.close_price,
        highest_price=payload.highest_price,
        lowest_price=payload.lowest_price,
        trading_volume=payload.trading_volume,
        trading_value=payload.trading_value,
    )
    db.add(candle)
    db.commit()
    db.refresh(candle)

    return AdminPriceHistoryResponse(
        price_history_id=candle.price_history_id,
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        recorded_date=candle.recorded_date,
        open_price=_fmt(candle.open_price),
        close_price=_fmt(candle.close_price),
        highest_price=_fmt(candle.highest_price),
        lowest_price=_fmt(candle.lowest_price),
        trading_volume=candle.trading_volume,
        trading_value=_fmt(candle.trading_value),
    )


@router.put("/price-history/{history_id}", response_model=AdminPriceHistoryResponse)
def update_price_history(
    history_id: int,
    payload: AdminPriceHistoryUpdate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminPriceHistoryResponse:
    """Update historical OHLCV data."""
    candle = (
        db.query(StockPriceHistory).filter(StockPriceHistory.price_history_id == history_id).first()
    )
    if candle is None:
        raise NotFoundException(message="Không tìm thấy phiên giá lịch sử.")

    if payload.open_price is not None:
        candle.open_price = payload.open_price
    if payload.close_price is not None:
        candle.close_price = payload.close_price
    if payload.highest_price is not None:
        candle.highest_price = payload.highest_price
    if payload.lowest_price is not None:
        candle.lowest_price = payload.lowest_price
    if payload.trading_volume is not None:
        candle.trading_volume = payload.trading_volume
    if payload.trading_value is not None:
        candle.trading_value = payload.trading_value

    db.commit()
    db.refresh(candle)

    return AdminPriceHistoryResponse(
        price_history_id=candle.price_history_id,
        stock_id=candle.stock_id,
        stock_symbol=candle.stock.stock_symbol if candle.stock else "",
        recorded_date=candle.recorded_date,
        open_price=_fmt(candle.open_price),
        close_price=_fmt(candle.close_price),
        highest_price=_fmt(candle.highest_price),
        lowest_price=_fmt(candle.lowest_price),
        trading_volume=candle.trading_volume,
        trading_value=_fmt(candle.trading_value),
    )


@router.delete("/price-history/{history_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_price_history(
    history_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Delete a daily candlestick record."""
    candle = (
        db.query(StockPriceHistory).filter(StockPriceHistory.price_history_id == history_id).first()
    )
    if candle is None:
        raise NotFoundException(message="Không tìm thấy bản ghi giá cần xóa.")

    db.delete(candle)
    db.commit()


# =====================================================================
# 8. NOTIFICATIONS CRUD & BROADCAST
# =====================================================================


@router.get("/notifications", response_model=AdminPage[AdminNotificationResponse])
def list_notifications(
    _: CurrentAdminDep,
    customer_id: int | None = Query(default=None),
    notification_type: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminNotificationResponse]:
    """Retrieve system notifications sent to customers."""
    query = db.query(Notification).join(Customer)
    if customer_id:
        query = query.filter(Notification.customer_id == customer_id)
    if notification_type:
        query = query.filter(Notification.notification_type == notification_type.upper())

    total = query.count()
    notifs = (
        query.order_by(Notification.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminNotificationResponse(
            notification_id=n.notification_id,
            customer_id=n.customer_id,
            customer_name=n.customer.full_name if n.customer else "",
            title=n.title,
            content=n.content,
            notification_type=n.notification_type,
            ref_id=n.ref_id,
            is_read=n.is_read,
            created_at=n.created_at,
        )
        for n in notifs
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/notifications", response_model=AdminNotificationResponse, status_code=status.HTTP_201_CREATED
)
def create_or_broadcast_notification(
    payload: AdminNotificationCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminNotificationResponse:
    """Send a notification to a specific customer or broadcast to all active customers."""
    if payload.customer_id is not None:
        customer = db.query(Customer).filter(Customer.customer_id == payload.customer_id).first()
        if customer is None:
            raise NotFoundException(message="Không tìm thấy khách hàng để gửi thông báo.")

        notif = Notification(
            customer_id=customer.customer_id,
            title=payload.title,
            content=payload.content,
            notification_type=payload.notification_type.upper(),
            ref_id=payload.ref_id,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)

        return AdminNotificationResponse(
            notification_id=notif.notification_id,
            customer_id=notif.customer_id,
            customer_name=customer.full_name,
            title=notif.title,
            content=notif.content,
            notification_type=notif.notification_type,
            ref_id=notif.ref_id,
            is_read=notif.is_read,
            created_at=notif.created_at,
        )

    # Broadcast to all active customers
    active_customers = db.query(Customer).filter(Customer.status == "ACTIVE").all()
    created_notifs: list[Notification] = []
    for c in active_customers:
        n = Notification(
            customer_id=c.customer_id,
            title=payload.title,
            content=payload.content,
            notification_type=payload.notification_type.upper(),
            ref_id=payload.ref_id,
        )
        db.add(n)
        created_notifs.append(n)

    db.commit()
    first = created_notifs[0] if created_notifs else None
    return AdminNotificationResponse(
        notification_id=first.notification_id if first else 0,
        customer_id=0,
        customer_name="[TOÀN BỘ KHÁCH HÀNG]",
        title=payload.title,
        content=f"[Broadcast đến {len(created_notifs)} khách hàng] {payload.content}",
        notification_type=payload.notification_type.upper(),
        ref_id=payload.ref_id,
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )


@router.delete("/notifications/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(
    notification_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Delete a notification record."""
    notif = db.query(Notification).filter(Notification.notification_id == notification_id).first()
    if notif is None:
        raise NotFoundException(message="Không tìm thấy thông báo cần xóa.")

    db.delete(notif)
    db.commit()


# =====================================================================
# 9. WATCHLISTS CRUD
# =====================================================================


@router.get("/watchlists", response_model=AdminPage[AdminWatchlistResponse])
def list_watchlists(
    _: CurrentAdminDep,
    customer_id: int | None = Query(default=None),
    stock_symbol: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> AdminPage[AdminWatchlistResponse]:
    """Retrieve customer watchlist entries."""
    query = db.query(Watchlist).join(Stock).join(Customer)
    if customer_id:
        query = query.filter(Watchlist.customer_id == customer_id)
    if stock_symbol:
        query = query.filter(Stock.stock_symbol == stock_symbol.upper().strip())

    total = query.count()
    watchlists = (
        query.order_by(Watchlist.watchlist_id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminWatchlistResponse(
            watchlist_id=w.watchlist_id,
            customer_id=w.customer_id,
            customer_name=w.customer.full_name if w.customer else "",
            stock_id=w.stock_id,
            stock_symbol=w.stock.stock_symbol if w.stock else "",
            company_name=w.stock.company_name if w.stock else "",
            list_name=w.list_name,
            target_price=_fmt(w.target_price) if w.target_price else None,
            note=w.note,
            created_at=w.created_at,
        )
        for w in watchlists
    ]

    return AdminPage(items=items, page=page, page_size=page_size, total=total)


@router.post(
    "/watchlists", response_model=AdminWatchlistResponse, status_code=status.HTTP_201_CREATED
)
def create_watchlist_entry(
    payload: AdminWatchlistCreate,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> AdminWatchlistResponse:
    """Add a stock to a customer's watchlist."""
    customer = db.query(Customer).filter(Customer.customer_id == payload.customer_id).first()
    if customer is None:
        raise NotFoundException(message="Không tìm thấy khách hàng.")

    stock = (
        db.query(Stock).filter(Stock.stock_symbol == payload.stock_symbol.upper().strip()).first()
    )
    if stock is None:
        raise NotFoundException(message=f"Không tìm thấy mã cổ phiếu {payload.stock_symbol}.")

    existing = (
        db.query(Watchlist)
        .filter(
            Watchlist.customer_id == payload.customer_id,
            Watchlist.stock_id == stock.stock_id,
            Watchlist.list_name == payload.list_name,
        )
        .first()
    )
    if existing:
        raise ConflictException(
            message=f"Mã {stock.stock_symbol} đã có trong danh mục theo dõi của khách hàng.",
            code="WATCHLIST_EXISTS",
        )

    w = Watchlist(
        customer_id=customer.customer_id,
        stock_id=stock.stock_id,
        list_name=payload.list_name,
        target_price=payload.target_price,
        note=payload.note,
    )
    db.add(w)
    db.commit()
    db.refresh(w)

    return AdminWatchlistResponse(
        watchlist_id=w.watchlist_id,
        customer_id=customer.customer_id,
        customer_name=customer.full_name,
        stock_id=stock.stock_id,
        stock_symbol=stock.stock_symbol,
        company_name=stock.company_name,
        list_name=w.list_name,
        target_price=_fmt(w.target_price) if w.target_price else None,
        note=w.note,
        created_at=w.created_at,
    )


@router.delete("/watchlists/{watchlist_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_watchlist_entry(
    watchlist_id: int,
    _: CurrentAdminDep,
    db: Session = Depends(get_db),
) -> None:
    """Remove a stock from a customer's watchlist."""
    w = db.query(Watchlist).filter(Watchlist.watchlist_id == watchlist_id).first()
    if w is None:
        raise NotFoundException(message="Không tìm thấy mã trong watchlist cần xóa.")

    db.delete(w)
    db.commit()
