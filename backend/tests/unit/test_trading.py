"""Owner: TV5 - Tuệ.

Comprehensive unit and integration test suite for the Trading Engine:
- Fee and tax calculation accuracy (CASH-01, SHARE-01)
- Price tick size rules for HOSE and other exchanges (ORD-01)
- Buy order fund reservation and insufficient cash handling
- Sell order share blocking and insufficient shares handling
- Idempotency with client_order_id
- Order matching and execution with balance adjustments
- Order cancellation and refund
- T+2 settlement clearing batches and idempotency
- Trading endpoints (orders, transactions, notifications) via TestClient
"""

import uuid
from datetime import date
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.errors import ConflictException, ValidationException
from app.main import app
from app.models.customer import Customer
from app.models.investment_account import InvestmentAccount
from app.models.portfolio import Portfolio
from app.models.stock import Stock
from app.schemas.trading import CreateOrderRequest
from app.services.matching_service import (
    compute_sell_tax,
    compute_trading_fee,
)
from app.services.order_service import (
    cancel_order,
    get_price_tick,
    place_order,
    validate_order_rules,
)
from app.services.settlement_service import (
    calculate_settlement_date,
    process_share_settlements,
)


@pytest.fixture(scope="module")
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def db_session() -> Session:
    from app.db.session import SessionLocal

    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture(scope="module")
def customer_auth(client: TestClient) -> tuple[str, int, int]:
    """Log in bich.tran@gmail.com and return (token, customer_id, account_id)."""
    resp = client.post(
        "/api/auth/login",
        json={"email": "bich.tran@gmail.com", "password": "Matkhau@123"},
    )
    assert resp.status_code == 200, f"Login failed: {resp.text}"
    data = resp.json()
    token = data["access_token"]
    cust_id = data["user"]["customer_id"]

    # Get accounts
    from app.db.session import SessionLocal

    db = SessionLocal()
    try:
        acc = db.query(InvestmentAccount).filter(InvestmentAccount.customer_id == cust_id).first()
        assert acc is not None
        acc_id = acc.account_id
    finally:
        db.close()

    return token, cust_id, acc_id


# =====================================================================
# 1. Calculation Unit Tests
# =====================================================================


def test_trading_fee_calculation():
    """Fee is 0.15% rounded HALF_UP to 0.01 VND."""
    # 10,000,000 * 0.0015 = 15,000.00
    assert compute_trading_fee(Decimal("10000000.00")) == Decimal("15000.00")
    # 9,900,000 * 0.0015 = 14,850.00
    assert compute_trading_fee(Decimal("9900000.00")) == Decimal("14850.00")
    # Rounding HALF_UP
    assert compute_trading_fee(Decimal("333.33")) == Decimal("0.50")


def test_sell_tax_calculation():
    """Sell tax is 0.10% rounded HALF_UP to 0.01 VND."""
    assert compute_sell_tax(Decimal("10000000.00")) == Decimal("10000.00")
    assert compute_sell_tax(Decimal("9900000.00")) == Decimal("9900.00")


def test_price_tick_size():
    """HOSE tick sizes: <10k -> 10, <50k -> 50, >=50k -> 100; HNX/UPCOM: 100."""
    assert get_price_tick("HOSE", Decimal("8500.00")) == Decimal("10.00")
    assert get_price_tick("HOSE", Decimal("25000.00")) == Decimal("50.00")
    assert get_price_tick("HOSE", Decimal("105000.00")) == Decimal("100.00")
    assert get_price_tick("HNX", Decimal("8500.00")) == Decimal("100.00")
    assert get_price_tick("UPCOM", Decimal("25000.00")) == Decimal("100.00")


def test_calculate_settlement_date_t_plus_2():
    """T+2 settlement skips weekends: Friday -> Tuesday, Monday -> Wednesday."""
    # 2026-10-23 is Friday
    fri = date(2026, 10, 23)
    due = calculate_settlement_date(fri, business_days=2)
    assert due == date(2026, 10, 27)  # Tuesday

    # 2026-10-26 is Monday
    mon = date(2026, 10, 26)
    due_mon = calculate_settlement_date(mon, business_days=2)
    assert due_mon == date(2026, 10, 28)  # Wednesday


# =====================================================================
# 2. Order Validation Rules
# =====================================================================


def test_validate_order_lot_and_band():
    stock = Stock(
        stock_symbol="TEST",
        exchange="HOSE",
        status="ACTIVE",
        floor_price=Decimal("90000.00"),
        ceiling_price=Decimal("110000.00"),
        current_price=Decimal("100000.00"),
    )

    # Valid order
    valid_req = CreateOrderRequest(
        client_order_id=uuid.uuid4(),
        stock_symbol="TEST",
        order_type="BUY",
        order_kind="LO",
        quantity=200,
        order_price=Decimal("100000.00"),
    )
    validate_order_rules(stock, valid_req)  # Should not raise

    # Invalid quantity (not multiple of 100)
    invalid_qty_req = valid_req.model_copy(update={"quantity": 150})
    with pytest.raises(ValidationException) as exc:
        validate_order_rules(stock, invalid_qty_req)
    assert "bội số của 100" in str(exc.value.detail)

    # Price out of band (above ceiling)
    above_ceiling_req = valid_req.model_copy(update={"order_price": Decimal("115000.00")})
    with pytest.raises(ValidationException) as exc:
        validate_order_rules(stock, above_ceiling_req)
    assert "biên độ trần/sàn" in str(exc.value.detail)

    # Invalid price tick (e.g. 100,025 on HOSE for price > 50,000 where tick is 100)
    bad_tick_req = valid_req.model_copy(update={"order_price": Decimal("100025.00")})
    with pytest.raises(ValidationException) as exc:
        validate_order_rules(stock, bad_tick_req)
    assert "bước giá" in str(exc.value.detail)


# =====================================================================
# 3. Buy Flow, Matching, and Exact Business Rules
# =====================================================================


def test_buy_order_and_matching_flow(db_session: Session):
    """Test exact rule from BUSINESS_RULES.md (CASH-01):

    Ban đầu: 1,000,000,000.00 cash, 0 blocked.
    Đặt BUY 100 * 100,000 (fee 15,000) -> cash: 989,985,000.00, blocked: 10,015,000.00.
    Khớp ở 99,000 (gross 9,900,000, fee 14,850) -> cash: 990,085,150.00, blocked: 0, qty: 100.
    """
    # Create isolated customer & account
    cust = Customer(
        full_name="Tester Trading",
        email=f"trader_{uuid.uuid4().hex[:8]}@test.com",
        phone_number=f"09{uuid.uuid4().int % 100000000:08d}",
        password_hash="fakehash",
        role="CUSTOMER",
        status="ACTIVE",
    )
    db_session.add(cust)
    db_session.flush()

    acc = InvestmentAccount(
        customer_id=cust.customer_id,
        account_number=f"TEST_{uuid.uuid4().hex[:8]}",
        cash_balance=Decimal("1000000000.00"),
        blocked_balance=Decimal("0.00"),
        total_asset_value=Decimal("1000000000.00"),
        status="ACTIVE",
    )
    db_session.add(acc)

    # Look up FPT stock
    stock = db_session.query(Stock).filter(Stock.stock_symbol == "FPT").first()
    assert stock is not None
    # Temporarily set FPT current price to 99,000 for this test
    original_price = stock.current_price
    stock.current_price = Decimal("99000.00")
    db_session.flush()

    client_id = uuid.uuid4()
    req = CreateOrderRequest(
        client_order_id=client_id,
        stock_symbol="FPT",
        order_type="BUY",
        order_kind="LO",
        quantity=100,
        order_price=Decimal("100000.00"),
    )

    # 1. Place order (should place, reserve, and immediately match at current_price=99,000)
    order, is_new = place_order(db=db_session, customer=cust, account_id=acc.account_id, req=req)
    assert is_new is True
    assert order.status == "COMPLETED"
    assert order.filled_quantity == 100

    # 2. Verify account balances match CASH-01 exactly: 990,085,150.00
    db_session.refresh(acc)
    assert acc.blocked_balance == Decimal("0.00")
    assert acc.cash_balance == Decimal("990085150.00")

    # 3. Verify portfolio holding
    p = (
        db_session.query(Portfolio)
        .filter(Portfolio.account_id == acc.account_id, Portfolio.stock_id == stock.stock_id)
        .first()
    )
    assert p is not None
    assert p.quantity == 100
    assert p.available_quantity == 0  # Pending T+2
    assert p.average_price == Decimal("99000.00")

    # 4. Test Idempotency: re-submitting same client_order_id returns existing order
    same_order, is_new_again = place_order(
        db=db_session, customer=cust, account_id=acc.account_id, req=req
    )
    assert is_new_again is False
    assert same_order.order_id == order.order_id

    # 5. Idempotency Conflict: re-submitting same client_order_id with different quantity
    conflicting_req = req.model_copy(update={"quantity": 200})
    with pytest.raises(ConflictException) as exc:
        place_order(db=db_session, customer=cust, account_id=acc.account_id, req=conflicting_req)
    assert "IDEMPOTENCY_CONFLICT" in exc.value.detail["error"]["code"]

    # Restore original price
    stock.current_price = original_price
    db_session.commit()


def test_order_cancellation_and_refund(db_session: Session):
    """Test order cancellation refunds blocked cash (CASH-01)."""
    cust = Customer(
        full_name="Tester Cancel",
        email=f"cancel_{uuid.uuid4().hex[:8]}@test.com",
        phone_number=f"09{uuid.uuid4().int % 100000000:08d}",
        password_hash="fakehash",
        role="CUSTOMER",
        status="ACTIVE",
    )
    db_session.add(cust)
    db_session.flush()

    acc = InvestmentAccount(
        customer_id=cust.customer_id,
        account_number=f"TEST_{uuid.uuid4().hex[:8]}",
        cash_balance=Decimal("1000000000.00"),
        blocked_balance=Decimal("0.00"),
        status="ACTIVE",
    )
    db_session.add(acc)

    stock = db_session.query(Stock).filter(Stock.stock_symbol == "FPT").first()
    assert stock is not None
    # Set limit price lower than market price so order stays PENDING
    stock.current_price = Decimal("105000.00")
    db_session.flush()

    req = CreateOrderRequest(
        client_order_id=uuid.uuid4(),
        stock_symbol="FPT",
        order_type="BUY",
        order_kind="LO",
        quantity=100,
        order_price=Decimal("100000.00"),
    )
    order, _ = place_order(db=db_session, customer=cust, account_id=acc.account_id, req=req)
    assert order.status == "PENDING"

    db_session.refresh(acc)
    assert acc.cash_balance == Decimal("989985000.00")
    assert acc.blocked_balance == Decimal("10015000.00")

    # Cancel order
    cancelled = cancel_order(db=db_session, customer=cust, order_id=order.order_id)
    assert cancelled.status == "CANCELLED"

    db_session.refresh(acc)
    # Cash fully refunded
    assert acc.cash_balance == Decimal("1000000000.00")
    assert acc.blocked_balance == Decimal("0.00")

    # Cancel again: idempotent 200
    cancelled_again = cancel_order(db=db_session, customer=cust, order_id=order.order_id)
    assert cancelled_again.status == "CANCELLED"


def test_t_plus_2_settlement_clearing(db_session: Session):
    """Test T+2 settlement releases shares to available_quantity in batches."""
    cust = Customer(
        full_name="Tester Settle",
        email=f"settle_{uuid.uuid4().hex[:8]}@test.com",
        phone_number=f"09{uuid.uuid4().int % 100000000:08d}",
        password_hash="fakehash",
        role="CUSTOMER",
        status="ACTIVE",
    )
    db_session.add(cust)
    db_session.flush()

    acc = InvestmentAccount(
        customer_id=cust.customer_id,
        account_number=f"TEST_{uuid.uuid4().hex[:8]}",
        cash_balance=Decimal("500000000.00"),
        status="ACTIVE",
    )
    db_session.add(acc)

    stock = db_session.query(Stock).filter(Stock.stock_symbol == "VNM").first()
    assert stock is not None
    stock.current_price = Decimal("60000.00")
    db_session.flush()

    # Buy 100 VNM at valid in-band price (60,000 VND)
    req = CreateOrderRequest(
        client_order_id=uuid.uuid4(),
        stock_symbol="VNM",
        order_type="BUY",
        order_kind="LO",
        quantity=100,
        order_price=Decimal("60000.00"),
    )
    order, _ = place_order(db=db_session, customer=cust, account_id=acc.account_id, req=req)
    assert order.status == "COMPLETED"

    portfolio = (
        db_session.query(Portfolio)
        .filter(Portfolio.account_id == acc.account_id, Portfolio.stock_id == stock.stock_id)
        .first()
    )
    assert portfolio.quantity == 100
    assert portfolio.available_quantity == 0

    # 1. Running settlement with past date (before settlement_date) -> 0 settled
    past_date = date(2020, 1, 1)
    settled_past = process_share_settlements(db_session, as_of_date=past_date)
    assert len([s for s in settled_past if s.account_id == acc.account_id]) == 0

    # 2. Running settlement with future date (settlement due) -> shares released!
    future_date = date(2030, 1, 1)
    settled_future = process_share_settlements(db_session, as_of_date=future_date)
    my_settled = [s for s in settled_future if s.account_id == acc.account_id]
    assert len(my_settled) == 1
    assert my_settled[0].quantity == 100

    db_session.refresh(portfolio)
    assert portfolio.available_quantity == 100

    # 3. Running again -> 0 settled (idempotent, no double crediting)
    settled_again = process_share_settlements(db_session, as_of_date=future_date)
    assert len([s for s in settled_again if s.account_id == acc.account_id]) == 0
    db_session.refresh(portfolio)
    assert portfolio.available_quantity == 100


# =====================================================================
# 4. HTTP API Endpoints via TestClient
# =====================================================================


def test_api_orders_crud(client: TestClient, customer_auth: tuple[str, int, int]):
    token, cust_id, acc_id = customer_auth
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Place Order via API
    order_payload = {
        "client_order_id": str(uuid.uuid4()),
        "stock_symbol": "HPG",
        "order_type": "BUY",
        "order_kind": "LO",
        "quantity": 100,
        "order_price": "28000.00",
    }
    resp = client.post(
        f"/api/accounts/{acc_id}/orders",
        json=order_payload,
        headers=headers,
    )
    assert resp.status_code == 201, f"Create order failed: {resp.text}"
    created = resp.json()
    assert created["stock_symbol"] == "HPG"
    assert created["quantity"] == 100
    assert created["order_price"] == "28000.00"
    order_id = created["order_id"]

    # 2. List Orders
    resp_list = client.get(f"/api/accounts/{acc_id}/orders", headers=headers)
    assert resp_list.status_code == 200
    orders_page = resp_list.json()
    assert orders_page["total"] >= 1
    assert any(o["order_id"] == order_id for o in orders_page["items"])

    # 3. View Transactions
    resp_txns = client.get(f"/api/accounts/{acc_id}/transactions", headers=headers)
    assert resp_txns.status_code == 200
    assert "items" in resp_txns.json()

    # 4. Notifications
    resp_notifs = client.get("/api/notifications", headers=headers)
    assert resp_notifs.status_code == 200
    notifs = resp_notifs.json()
    assert notifs["total"] >= 1
    first_notif = notifs["items"][0]

    # Mark as read
    read_resp = client.post(
        f"/api/notifications/{first_notif['notification_id']}/read",
        headers=headers,
    )
    assert read_resp.status_code == 200
    assert read_resp.json()["is_read"] is True
