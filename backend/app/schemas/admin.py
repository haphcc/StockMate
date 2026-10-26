"""Owner: TV1 - Phuoc.

Pydantic schemas for Admin Portal API endpoints:
- Dashboard KPI statistics
- Full CRUD operations across all tables:
  * Customers (with cascade delete)
  * Investment Accounts
  * Stocks
  * Stock Orders
  * Transactions
  * Portfolios
  * Stock Price History
  * Notifications (Broadcast & Targeted)
  * Watchlists
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Generic, TypeVar

from pydantic import BaseModel, ConfigDict, EmailStr, Field

T = TypeVar("T")


class AdminPage(BaseModel, Generic[T]):
    """Standard pagination envelope for Admin listings."""

    items: list[T]
    page: int
    page_size: int
    total: int


# =====================================================================
# 1. CUSTOMERS
# =====================================================================


class AdminCustomerCreate(BaseModel):
    """Schema for creating a new customer or admin user."""

    full_name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone_number: str = Field(..., min_length=9, max_length=15)
    password: str = Field(..., min_length=6)
    role: str = Field(default="CUSTOMER", pattern="^(CUSTOMER|ADMIN)$")
    status: str = Field(default="ACTIVE", pattern="^(PENDING|ACTIVE|LOCKED|CLOSED)$")
    date_of_birth: date | None = None
    id_card_number: str | None = Field(default=None, max_length=20)
    address: str | None = Field(default=None, max_length=255)
    avatar_url: str | None = Field(default=None, max_length=255)
    initial_cash_balance: Decimal = Field(default=Decimal("0.00"), ge=0)


class AdminCustomerUpdate(BaseModel):
    """Schema for updating an existing customer."""

    full_name: str | None = Field(default=None, min_length=2, max_length=100)
    email: EmailStr | None = None
    phone_number: str | None = Field(default=None, min_length=9, max_length=15)
    password: str | None = Field(default=None, min_length=6)
    role: str | None = Field(default=None, pattern="^(CUSTOMER|ADMIN)$")
    status: str | None = Field(default=None, pattern="^(PENDING|ACTIVE|LOCKED|CLOSED)$")
    date_of_birth: date | None = None
    id_card_number: str | None = Field(default=None, max_length=20)
    address: str | None = Field(default=None, max_length=255)
    avatar_url: str | None = Field(default=None, max_length=255)


class AdminCustomerResponse(BaseModel):
    """Customer summary response for administrative views."""

    model_config = ConfigDict(from_attributes=True)

    customer_id: int
    full_name: str
    email: str
    phone_number: str
    role: str
    status: str
    date_of_birth: date | None = None
    id_card_number: str | None = None
    address: str | None = None
    avatar_url: str | None = None
    created_at: datetime
    updated_at: datetime
    accounts_count: int = 0


# =====================================================================
# 2. INVESTMENT ACCOUNTS
# =====================================================================


class AdminAccountCreate(BaseModel):
    """Schema for creating a new trading account for a customer."""

    customer_id: int
    account_number: str | None = None
    account_type: str = Field(default="CASH", pattern="^(CASH|MARGIN)$")
    cash_balance: Decimal = Field(default=Decimal("0.00"), ge=0)
    margin_limit: Decimal = Field(default=Decimal("0.00"), ge=0)
    status: str = Field(default="ACTIVE", pattern="^(ACTIVE|SUSPENDED|CLOSED)$")


class AdminAccountUpdate(BaseModel):
    """Schema for updating an investment account."""

    account_type: str | None = Field(default=None, pattern="^(CASH|MARGIN)$")
    cash_balance: Decimal | None = Field(default=None, ge=0)
    blocked_balance: Decimal | None = Field(default=None, ge=0)
    total_asset_value: Decimal | None = Field(default=None, ge=0)
    margin_limit: Decimal | None = Field(default=None, ge=0)
    status: str | None = Field(default=None, pattern="^(ACTIVE|SUSPENDED|CLOSED)$")


class AdminAccountResponse(BaseModel):
    """Investment account response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    account_id: int
    customer_id: int
    customer_name: str = ""
    customer_email: str = ""
    account_number: str
    account_type: str
    cash_balance: str
    blocked_balance: str
    total_asset_value: str
    margin_limit: str
    status: str
    created_at: datetime
    updated_at: datetime


class AdminCustomerDetailResponse(AdminCustomerResponse):
    """Detailed customer profile with associated trading accounts and watchlists."""

    accounts: list[AdminAccountResponse] = []


# =====================================================================
# 3. STOCKS
# =====================================================================


class AdminStockCreate(BaseModel):
    """Schema for creating a new stock symbol."""

    stock_symbol: str = Field(..., min_length=3, max_length=10)
    company_name: str = Field(..., min_length=2, max_length=200)
    exchange: str = Field(..., pattern="^(HOSE|HNX|UPCOM)$")
    industry: str | None = Field(default=None, max_length=100)
    listed_shares: int = Field(default=0, ge=0)
    current_price: Decimal = Field(..., ge=0)
    reference_price: Decimal = Field(..., ge=0)
    ceiling_price: Decimal | None = None
    floor_price: Decimal | None = None
    status: str = Field(default="ACTIVE", pattern="^(ACTIVE|HALTED|DELISTED)$")


class AdminStockUpdate(BaseModel):
    """Schema for updating a stock."""

    company_name: str | None = Field(default=None, min_length=2, max_length=200)
    exchange: str | None = Field(default=None, pattern="^(HOSE|HNX|UPCOM)$")
    industry: str | None = Field(default=None, max_length=100)
    listed_shares: int | None = Field(default=None, ge=0)
    current_price: Decimal | None = Field(default=None, ge=0)
    reference_price: Decimal | None = Field(default=None, ge=0)
    ceiling_price: Decimal | None = Field(default=None, ge=0)
    floor_price: Decimal | None = Field(default=None, ge=0)
    total_volume: int | None = Field(default=None, ge=0)
    status: str | None = Field(default=None, pattern="^(ACTIVE|HALTED|DELISTED)$")


class AdminStockResponse(BaseModel):
    """Stock response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    stock_id: int
    stock_symbol: str
    company_name: str
    exchange: str
    industry: str | None = None
    listed_shares: int
    current_price: str
    reference_price: str
    ceiling_price: str
    floor_price: str
    price_change: str = "0.00"
    change_percent: str = "0.00"
    total_volume: int
    status: str
    updated_at: datetime


# =====================================================================
# 4. STOCK ORDERS
# =====================================================================


class AdminOrderUpdate(BaseModel):
    """Schema for admin intervention on orders."""

    status: str | None = Field(
        default=None, pattern="^(PENDING|PARTIAL|COMPLETED|CANCELLED|REJECTED)$"
    )
    filled_quantity: int | None = Field(default=None, ge=0)
    reject_reason: str | None = Field(default=None, max_length=255)


class AdminOrderResponse(BaseModel):
    """Stock order detail for admin oversight."""

    model_config = ConfigDict(from_attributes=True)

    order_id: int
    account_id: int
    account_number: str = ""
    customer_name: str = ""
    stock_id: int
    stock_symbol: str
    client_order_id: str
    order_type: str
    order_kind: str
    quantity: int
    filled_quantity: int
    remaining_quantity: int = 0
    order_price: str
    order_date: datetime
    matched_at: datetime | None = None
    status: str
    reject_reason: str | None = None


# =====================================================================
# 5. TRANSACTIONS
# =====================================================================


class AdminTransactionCreate(BaseModel):
    """Schema for recording a trade transaction manually."""

    account_id: int
    order_id: int | None = None
    stock_symbol: str
    transaction_type: str = Field(..., pattern="^(BUY|SELL)$")
    quantity: int = Field(..., gt=0)
    price: Decimal = Field(..., gt=0)
    transaction_fee: Decimal = Field(default=Decimal("0.00"), ge=0)
    tax_amount: Decimal = Field(default=Decimal("0.00"), ge=0)
    settlement_date: date | None = None


class AdminTransactionResponse(BaseModel):
    """Transaction response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    transaction_id: int
    order_id: int
    account_id: int
    account_number: str = ""
    stock_id: int
    stock_symbol: str
    transaction_type: str
    quantity: int
    price: str
    total_amount: str
    transaction_fee: str
    tax_amount: str
    net_amount: str
    transaction_date: datetime
    settlement_date: date | None = None


# =====================================================================
# 6. PORTFOLIOS
# =====================================================================


class AdminPortfolioCreate(BaseModel):
    """Schema for adding stock holding to an account."""

    account_id: int
    stock_symbol: str
    quantity: int = Field(..., ge=0)
    available_quantity: int = Field(..., ge=0)
    blocked_quantity: int = Field(default=0, ge=0)
    average_price: Decimal = Field(..., ge=0)


class AdminPortfolioUpdate(BaseModel):
    """Schema for adjusting portfolio holdings."""

    quantity: int | None = Field(default=None, ge=0)
    available_quantity: int | None = Field(default=None, ge=0)
    blocked_quantity: int | None = Field(default=None, ge=0)
    average_price: Decimal | None = Field(default=None, ge=0)


class AdminPortfolioResponse(BaseModel):
    """Portfolio response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    portfolio_id: int
    account_id: int
    account_number: str = ""
    customer_name: str = ""
    stock_id: int
    stock_symbol: str
    company_name: str = ""
    quantity: int
    available_quantity: int
    blocked_quantity: int
    average_price: str
    current_value: str
    profit_loss: str
    profit_loss_percent: str = "0.00"
    updated_at: datetime


# =====================================================================
# 7. STOCK PRICE HISTORY
# =====================================================================


class AdminPriceHistoryCreate(BaseModel):
    """Schema for adding historical daily OHLCV candle."""

    stock_id: int | None = None
    stock_symbol: str | None = None
    recorded_date: date
    open_price: Decimal = Field(..., ge=0)
    close_price: Decimal = Field(..., ge=0)
    highest_price: Decimal = Field(..., ge=0)
    lowest_price: Decimal = Field(..., ge=0)
    trading_volume: int = Field(default=0, ge=0)
    trading_value: Decimal = Field(default=Decimal("0.00"), ge=0)


class AdminPriceHistoryUpdate(BaseModel):
    """Schema for updating OHLCV candlestick data."""

    open_price: Decimal | None = Field(default=None, ge=0)
    close_price: Decimal | None = Field(default=None, ge=0)
    highest_price: Decimal | None = Field(default=None, ge=0)
    lowest_price: Decimal | None = Field(default=None, ge=0)
    trading_volume: int | None = Field(default=None, ge=0)
    trading_value: Decimal | None = Field(default=None, ge=0)


class AdminPriceHistoryResponse(BaseModel):
    """Historical OHLCV response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    price_history_id: int
    stock_id: int
    stock_symbol: str = ""
    recorded_date: date
    open_price: str
    close_price: str
    highest_price: str
    lowest_price: str
    trading_volume: int
    trading_value: str


# =====================================================================
# 8. NOTIFICATIONS
# =====================================================================


class AdminNotificationCreate(BaseModel):
    """Schema for sending targeted or broadcast notifications."""

    customer_id: int | None = None  # None = Broadcast to all active customers
    title: str = Field(..., min_length=2, max_length=200)
    content: str = Field(..., min_length=2)
    notification_type: str = Field(
        default="SYSTEM", pattern="^(ORDER|TRANSACTION|PRICE_ALERT|CASH|SYSTEM|NEWS)$"
    )
    ref_id: int | None = None


class AdminNotificationResponse(BaseModel):
    """Notification response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    notification_id: int
    customer_id: int
    customer_name: str = ""
    title: str
    content: str
    notification_type: str
    ref_id: int | None = None
    is_read: bool
    created_at: datetime


# =====================================================================
# 9. WATCHLISTS
# =====================================================================


class AdminWatchlistCreate(BaseModel):
    """Schema for adding a stock to a customer's watchlist."""

    customer_id: int
    stock_symbol: str
    list_name: str = Field(default="Danh muc theo doi", max_length=50)
    target_price: Decimal | None = Field(default=None, ge=0)
    note: str | None = Field(default=None, max_length=255)


class AdminWatchlistResponse(BaseModel):
    """Watchlist response for admin views."""

    model_config = ConfigDict(from_attributes=True)

    watchlist_id: int
    customer_id: int
    customer_name: str = ""
    stock_id: int
    stock_symbol: str
    company_name: str = ""
    list_name: str
    target_price: str | None = None
    note: str | None = None
    created_at: datetime


# =====================================================================
# 10. DASHBOARD KPI SUMMARY
# =====================================================================


class AdminDashboardKPIs(BaseModel):
    """Consolidated KPI metric counts and totals across the exchange."""

    # Customers
    total_customers: int
    active_customers: int
    locked_customers: int
    admin_count: int

    # Accounts
    total_accounts: int
    active_accounts: int
    suspended_accounts: int
    total_cash_balance: str
    total_asset_value: str

    # Stocks
    total_stocks: int
    active_stocks: int
    halted_stocks: int

    # Orders & Trading
    total_orders_today: int
    pending_orders: int
    completed_orders: int
    cancelled_orders: int
    total_transactions_today: int
    total_trading_volume_today: int
    total_trading_value_today: str


class AdminDashboardResponse(BaseModel):
    """Aggregated dashboard response for administrative portal."""

    kpis: AdminDashboardKPIs
    recent_orders: list[AdminOrderResponse]
    recent_transactions: list[AdminTransactionResponse]
    top_stocks: list[AdminStockResponse]
    system_status: str = "OPERATIONAL"
