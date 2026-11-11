"""Owner: TV1 - Phuoc.

Comprehensive unit and integration test suite for the Admin Portal API:
- Health check endpoints
- Admin vs Customer authorization verification
- Admin Dashboard KPI computation
- Customer CRUD with cascade deletion
- Investment Account CRUD
- Stock CRUD
- Stock Order oversight and intervention
- Transaction adjustment CRUD
- Portfolio holdings CRUD
- Price History OHLCV CRUD
- Notification targeted and broadcast CRUD
- Watchlist oversight CRUD
"""

import sys
import uuid
from decimal import Decimal
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Ensure backend directory is in python sys.path
BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.main import app  # noqa: E402


@pytest.fixture(scope="module")
def client() -> TestClient:
    """Create FastAPI test client."""
    return TestClient(app)


@pytest.fixture(scope="module")
def admin_token(client: TestClient) -> str:
    """Authenticate default administrator (an.nguyen@gmail.com) and return access token."""
    response = client.post(
        "/api/auth/login",
        json={"email": "an.nguyen@gmail.com", "password": "Matkhau@123"},
    )
    assert response.status_code == 200, f"Admin login failed: {response.text}"
    data = response.json()
    assert data["user"]["role"] == "ADMIN"
    return data["access_token"]


@pytest.fixture(scope="module")
def customer_token(client: TestClient) -> str:
    """Authenticate regular customer (bich.tran@gmail.com) and return access token."""
    response = client.post(
        "/api/auth/login",
        json={"email": "bich.tran@gmail.com", "password": "Matkhau@123"},
    )
    assert response.status_code == 200, f"Customer login failed: {response.text}"
    data = response.json()
    assert data["user"]["role"] == "CUSTOMER"
    return data["access_token"]


# =====================================================================
# 1. HEALTH CHECKS
# =====================================================================


def test_health_live(client: TestClient) -> None:
    """Test process liveness probe."""
    res = client.get("/health/live")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_health_ready(client: TestClient) -> None:
    """Test database readiness probe."""
    res = client.get("/health/ready")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ready"
    assert data["database"] == "connected"


# =====================================================================
# 2. AUTHORIZATION & ACCESS CONTROL
# =====================================================================


def test_admin_access_unauthorized(client: TestClient) -> None:
    """Ensure unauthenticated access to admin endpoints is rejected with 401."""
    res = client.get("/api/admin/dashboard")
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "UNAUTHORIZED"


def test_admin_access_forbidden_for_customers(client: TestClient, customer_token: str) -> None:
    """Ensure regular CUSTOMER role receives 403 FORBIDDEN when attempting admin actions."""
    res = client.get(
        "/api/admin/dashboard",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "FORBIDDEN"


# =====================================================================
# 3. DASHBOARD SUMMARY
# =====================================================================


def test_admin_dashboard(client: TestClient, admin_token: str) -> None:
    """Test dashboard KPI aggregates and summary lists."""
    res = client.get(
        "/api/admin/dashboard",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert res.status_code == 200
    data = res.json()
    assert "kpis" in data
    kpis = data["kpis"]
    assert kpis["total_customers"] >= 1
    assert kpis["admin_count"] >= 1
    assert kpis["total_stocks"] >= 1
    assert Decimal(kpis["total_cash_balance"]) >= 0
    assert data["system_status"] == "OPERATIONAL"


# =====================================================================
# 4. CUSTOMERS CRUD & CASCADE DELETION
# =====================================================================


def test_customers_crud_and_cascade(client: TestClient, admin_token: str) -> None:
    """Full lifecycle of customer management: List, Create, Detail, Update, Cascade Delete."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List
    list_res = client.get("/api/admin/customers?page=1&page_size=10", headers=headers)
    assert list_res.status_code == 200
    assert list_res.json()["total"] >= 1

    # 2. Create with unique attributes
    unique_suffix = uuid.uuid4().hex[:6]
    test_email = f"test_phuoc_{unique_suffix}@example.com"
    test_phone = f"09{uuid.uuid4().int % 100000000:08d}"
    create_payload = {
        "full_name": "Phuoc Test Admin",
        "email": test_email,
        "phone_number": test_phone,
        "password": "Password@123",
        "role": "CUSTOMER",
        "status": "ACTIVE",
        "date_of_birth": "1995-10-20",
        "initial_cash_balance": "50000000.00",
    }
    create_res = client.post("/api/admin/customers", json=create_payload, headers=headers)
    assert create_res.status_code == 201
    created_cust = create_res.json()
    cust_id = created_cust["customer_id"]
    assert created_cust["email"] == test_email
    assert created_cust["accounts_count"] == 1

    # 3. Duplicate check
    dup_res = client.post("/api/admin/customers", json=create_payload, headers=headers)
    assert dup_res.status_code == 409
    assert dup_res.json()["error"]["code"] == "DUPLICATE_EMAIL"

    # 4. Detail
    detail_res = client.get(f"/api/admin/customers/{cust_id}", headers=headers)
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert len(detail["accounts"]) == 1
    acc_id = detail["accounts"][0]["account_id"]
    assert detail["accounts"][0]["cash_balance"] == "50000000.00"

    # 5. Update status and role
    update_res = client.put(
        f"/api/admin/customers/{cust_id}",
        json={"status": "LOCKED", "role": "ADMIN", "full_name": "Phuoc Updated"},
        headers=headers,
    )
    assert update_res.status_code == 200
    updated = update_res.json()
    assert updated["status"] == "LOCKED"
    assert updated["role"] == "ADMIN"
    assert updated["full_name"] == "Phuoc Updated"

    # 6. Delete (cascades account automatically)
    del_res = client.delete(f"/api/admin/customers/{cust_id}", headers=headers)
    assert del_res.status_code == 204

    # Verify deleted
    get_del_res = client.get(f"/api/admin/customers/{cust_id}", headers=headers)
    assert get_del_res.status_code == 404

    # Verify account was also cascaded
    get_acc_res = client.get(f"/api/admin/accounts/{acc_id}", headers=headers)
    assert get_acc_res.status_code == 404


# =====================================================================
# 5. INVESTMENT ACCOUNTS CRUD
# =====================================================================


def test_accounts_crud(client: TestClient, admin_token: str) -> None:
    """Full lifecycle of investment account management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List accounts
    res = client.get("/api/admin/accounts?page=1&page_size=10", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["total"] >= 1
    first_acc_id = data["items"][0]["account_id"]

    # 2. Get single account
    get_res = client.get(f"/api/admin/accounts/{first_acc_id}", headers=headers)
    assert get_res.status_code == 200

    # 3. Create a secondary MARGIN account for admin customer (id=1)
    create_payload = {
        "customer_id": 1,
        "account_type": "MARGIN",
        "cash_balance": "10000000.00",
        "margin_limit": "20000000.00",
        "status": "ACTIVE",
    }
    create_res = client.post("/api/admin/accounts", json=create_payload, headers=headers)
    assert create_res.status_code == 201
    new_acc = create_res.json()
    new_acc_id = new_acc["account_id"]
    assert new_acc["account_type"] == "MARGIN"
    assert new_acc["cash_balance"] == "10000000.00"

    # 4. Update account
    upd_res = client.put(
        f"/api/admin/accounts/{new_acc_id}",
        json={"cash_balance": "15000000.00", "status": "SUSPENDED"},
        headers=headers,
    )
    assert upd_res.status_code == 200
    assert upd_res.json()["cash_balance"] == "15000000.00"
    assert upd_res.json()["status"] == "SUSPENDED"

    # 5. Delete account
    del_res = client.delete(f"/api/admin/accounts/{new_acc_id}", headers=headers)
    assert del_res.status_code == 204


# =====================================================================
# 6. STOCKS CRUD
# =====================================================================


def test_stocks_crud(client: TestClient, admin_token: str) -> None:
    """Full lifecycle of listed securities management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List stocks
    res = client.get("/api/admin/stocks?q=FPT", headers=headers)
    assert res.status_code == 200
    assert res.json()["total"] >= 1

    # 2. Create new stock with unique symbol
    sym = f"T{uuid.uuid4().hex[:4].upper()}"
    create_payload = {
        "stock_symbol": sym,
        "company_name": "CTCP Kiểm Thử StockMate",
        "exchange": "HOSE",
        "industry": "Công nghệ thông tin",
        "listed_shares": 50000000,
        "reference_price": "25000.00",
        "current_price": "25500.00",
    }
    create_res = client.post("/api/admin/stocks", json=create_payload, headers=headers)
    assert create_res.status_code == 201
    created = create_res.json()
    stock_id = created["stock_id"]
    assert created["stock_symbol"] == sym
    assert created["ceiling_price"] == "26750.00"  # HOSE +7%

    # 3. Update stock
    upd_res = client.put(
        f"/api/admin/stocks/{stock_id}",
        json={"current_price": "26000.00", "status": "HALTED"},
        headers=headers,
    )
    assert upd_res.status_code == 200
    assert upd_res.json()["current_price"] == "26000.00"
    assert upd_res.json()["status"] == "HALTED"

    # 4. Delete stock
    del_res = client.delete(f"/api/admin/stocks/{stock_id}", headers=headers)
    assert del_res.status_code == 204


# =====================================================================
# 7. STOCK ORDERS OVERSIGHT & INTERVENTION
# =====================================================================


def test_orders_oversight(client: TestClient, admin_token: str) -> None:
    """Test administrative inspection and intervention on stock orders."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    res = client.get("/api/admin/orders?page=1&page_size=5", headers=headers)
    assert res.status_code == 200
    data = res.json()
    if data["items"]:
        order_id = data["items"][0]["order_id"]
        # Update order status
        upd_res = client.put(
            f"/api/admin/orders/{order_id}",
            json={"reject_reason": "Admin test verification"},
            headers=headers,
        )
        assert upd_res.status_code == 200
        assert upd_res.json()["reject_reason"] == "Admin test verification"


# =====================================================================
# 8. NOTIFICATIONS TARGETED & BROADCAST
# =====================================================================


def test_notifications_crud(client: TestClient, admin_token: str) -> None:
    """Test administrative notification creation (targeted and broadcast)."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Targeted notification to Customer 1
    targeted_payload = {
        "customer_id": 1,
        "title": "Thông báo quan trọng từ Admin",
        "content": "Hệ thống bảo trì lúc 23h00.",
        "notification_type": "SYSTEM",
    }
    t_res = client.post("/api/admin/notifications", json=targeted_payload, headers=headers)
    assert t_res.status_code == 201
    notif_id = t_res.json()["notification_id"]

    # 2. Broadcast notification to all customers
    bcast_payload = {
        "customer_id": None,
        "title": "Thông báo toàn sàn",
        "content": "Chúc mừng phiên giao dịch đầu năm mới!",
        "notification_type": "NEWS",
    }
    b_res = client.post("/api/admin/notifications", json=bcast_payload, headers=headers)
    assert b_res.status_code == 201
    assert "[Broadcast" in b_res.json()["content"]

    # 3. Delete notification
    del_res = client.delete(f"/api/admin/notifications/{notif_id}", headers=headers)
    assert del_res.status_code == 204


# =====================================================================
# 9. WATCHLISTS OVERSIGHT
# =====================================================================


def test_watchlists_crud(client: TestClient, admin_token: str) -> None:
    """Test administrative watchlist management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List watchlists
    list_res = client.get("/api/admin/watchlists?customer_id=1", headers=headers)
    assert list_res.status_code == 200

    # 2. Add stock to customer 1 watchlist
    add_payload = {
        "customer_id": 1,
        "stock_symbol": "VNM",
        "list_name": "Admin Watchlist",
        "target_price": "75000.00",
        "note": "Theo dõi điểm mua",
    }
    add_res = client.post("/api/admin/watchlists", json=add_payload, headers=headers)
    if add_res.status_code == 201:
        wid = add_res.json()["watchlist_id"]
        # Delete watchlist entry
        del_res = client.delete(f"/api/admin/watchlists/{wid}", headers=headers)
        assert del_res.status_code == 204
    elif add_res.status_code == 409:
        # Already existed
        pass


# =====================================================================
# 10. STOCK PRICE HISTORY (OHLCV)
# =====================================================================


def test_price_history_crud(client: TestClient, admin_token: str) -> None:
    """Test OHLCV candlestick records management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Create dummy candle for FPT on special historical date 2019-12-31
    create_payload = {
        "stock_symbol": "FPT",
        "recorded_date": "2019-12-31",
        "open_price": "45000.00",
        "close_price": "46000.00",
        "highest_price": "46500.00",
        "lowest_price": "44800.00",
        "trading_volume": 500000,
        "trading_value": "22800000000.00",
    }
    res = client.post("/api/admin/price-history", json=create_payload, headers=headers)
    if res.status_code == 201:
        hid = res.json()["price_history_id"]
        # Update
        upd = client.put(
            f"/api/admin/price-history/{hid}",
            json={"close_price": "46200.00"},
            headers=headers,
        )
        assert upd.status_code == 200
        assert upd.json()["close_price"] == "46200.00"
        # Delete
        del_res = client.delete(f"/api/admin/price-history/{hid}", headers=headers)
        assert del_res.status_code == 204


# =====================================================================
# 11. PORTFOLIOS CRUD
# =====================================================================


def test_portfolios_crud(client: TestClient, admin_token: str) -> None:
    """Test administrative portfolio holdings management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List portfolios
    list_res = client.get("/api/admin/portfolios?page=1&page_size=10", headers=headers)
    assert list_res.status_code == 200
    assert list_res.json()["total"] >= 1

    # 2. Add or update holding for Account 1 with symbol FPT or MBB
    p_payload = {
        "account_id": 1,
        "stock_symbol": "VNM",
        "quantity": 200,
        "available_quantity": 200,
        "blocked_quantity": 0,
        "average_price": "72000.00",
    }
    p_res = client.post("/api/admin/portfolios", json=p_payload, headers=headers)
    if p_res.status_code == 201:
        pid = p_res.json()["portfolio_id"]
        # Update
        upd = client.put(
            f"/api/admin/portfolios/{pid}",
            json={"quantity": 300, "available_quantity": 300},
            headers=headers,
        )
        assert upd.status_code == 200
        assert upd.json()["quantity"] == 300
        # Delete
        del_res = client.delete(f"/api/admin/portfolios/{pid}", headers=headers)
        assert del_res.status_code == 204


# =====================================================================
# 12. TRANSACTIONS CRUD
# =====================================================================


def test_transactions_crud(client: TestClient, admin_token: str) -> None:
    """Test administrative transaction records management."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. List transactions
    list_res = client.get("/api/admin/transactions?page=1&page_size=5", headers=headers)
    assert list_res.status_code == 200
    assert list_res.json()["total"] >= 1

    # 2. Create adjustment transaction
    create_payload = {
        "account_id": 1,
        "stock_symbol": "FPT",
        "transaction_type": "BUY",
        "quantity": 100,
        "price": "99000.00",
        "transaction_fee": "14850.00",
        "tax_amount": "0.00",
    }
    t_res = client.post("/api/admin/transactions", json=create_payload, headers=headers)
    assert t_res.status_code == 201
    tid = t_res.json()["transaction_id"]
    assert t_res.json()["stock_symbol"] == "FPT"

    # 3. Delete transaction
    del_res = client.delete(f"/api/admin/transactions/{tid}", headers=headers)
    assert del_res.status_code == 204


# =====================================================================
# 13. QA BUG FIXES & ADMIN ORDER INTERVENTION REGRESSION TESTS
# =====================================================================


def _create_temp_customer(
    client: TestClient, headers: dict[str, str], initial_cash: str = "10000000.00"
) -> tuple[int, int, str]:
    suffix = uuid.uuid4().hex[:8]
    email = f"qa_{suffix}@example.com"
    phone = f"09{uuid.uuid4().int % 100000000:08d}"
    res = client.post(
        "/api/admin/customers",
        json={
            "full_name": f"QA Tester {suffix}",
            "email": email,
            "phone_number": phone,
            "password": "Password@123",
            "initial_cash_balance": initial_cash,
        },
        headers=headers,
    )
    assert res.status_code == 201, res.text
    cid = res.json()["customer_id"]
    detail = client.get(f"/api/admin/customers/{cid}", headers=headers).json()
    acc_id = detail["accounts"][0]["account_id"]
    return cid, acc_id, email


def test_account_balance_validation_bug03(client: TestClient, admin_token: str) -> None:
    """BUG-03: Reject inconsistent balances and auto-recalc total asset value."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    cid, acc_id, _ = _create_temp_customer(client, headers)
    try:
        # 1. total_asset_value < cash_balance + blocked_balance -> 422
        bad_bal = client.put(
            f"/api/admin/accounts/{acc_id}",
            json={
                "cash_balance": "100.00",
                "blocked_balance": "999999.00",
                "total_asset_value": "50.00",
            },
            headers=headers,
        )
        assert bad_bal.status_code == 422
        assert bad_bal.json()["error"]["code"] == "INVALID_ACCOUNT_BALANCE"

        # 2. CASH account with margin_limit > 0 -> 422
        bad_margin = client.put(
            f"/api/admin/accounts/{acc_id}",
            json={"account_type": "CASH", "margin_limit": "5000000.00"},
            headers=headers,
        )
        assert bad_margin.status_code == 422
        assert bad_margin.json()["error"]["code"] == "INVALID_MARGIN_LIMIT"

        # 3. Updating only cash_balance auto-recalculates total_asset_value
        ok_upd = client.put(
            f"/api/admin/accounts/{acc_id}",
            json={"cash_balance": "25000000.00"},
            headers=headers,
        )
        assert ok_upd.status_code == 200
        assert ok_upd.json()["total_asset_value"] == "25000000.00"
    finally:
        client.delete(f"/api/admin/customers/{cid}", headers=headers)


def test_create_account_after_deletion_bug04(client: TestClient, admin_token: str) -> None:
    """BUG-04: Creating an account after deleting another must not collide."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    cid, acc1_id, _ = _create_temp_customer(client, headers)
    try:
        a2_res = client.post(
            "/api/admin/accounts",
            json={"customer_id": cid, "account_type": "CASH", "cash_balance": "1000000.00"},
            headers=headers,
        )
        assert a2_res.status_code == 201, a2_res.text
        acc2_num = a2_res.json()["account_number"]

        del_res = client.delete(f"/api/admin/accounts/{acc1_id}", headers=headers)
        assert del_res.status_code == 204

        a3_res = client.post(
            "/api/admin/accounts",
            json={"customer_id": cid, "account_type": "CASH", "cash_balance": "2000000.00"},
            headers=headers,
        )
        assert a3_res.status_code == 201, a3_res.text
        assert a3_res.json()["account_number"] != acc2_num
    finally:
        client.delete(f"/api/admin/customers/{cid}", headers=headers)


def test_stock_price_validation_and_recalc_bug05(client: TestClient, admin_token: str) -> None:
    """BUG-05: Reject invalid stock bands/prices and recalc limits on reference change."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    sym = f"Q{uuid.uuid4().hex[:4].upper()}"
    create_res = client.post(
        "/api/admin/stocks",
        json={
            "stock_symbol": sym,
            "company_name": "CTCP QA Price Check",
            "exchange": "HOSE",
            "reference_price": "20000.00",
            "current_price": "20000.00",
        },
        headers=headers,
    )
    assert create_res.status_code == 201, create_res.text
    stock_id = create_res.json()["stock_id"]
    try:
        # 1. ceiling < floor -> 422
        bad_band = client.put(
            f"/api/admin/stocks/{stock_id}",
            json={"ceiling_price": "10000.00", "floor_price": "30000.00"},
            headers=headers,
        )
        assert bad_band.status_code == 422
        assert bad_band.json()["error"]["code"] == "INVALID_PRICE_BAND"

        # 2. current_price > ceiling -> 422
        bad_cur = client.put(
            f"/api/admin/stocks/{stock_id}",
            json={"current_price": "99999.00"},
            headers=headers,
        )
        assert bad_cur.status_code == 422
        assert bad_cur.json()["error"]["code"] == "PRICE_OUT_OF_BAND"

        # 3. Updating reference_price without ceiling/floor recalculates both
        upd_ref = client.put(
            f"/api/admin/stocks/{stock_id}",
            json={"reference_price": "30000.00", "current_price": "30500.00"},
            headers=headers,
        )
        assert upd_ref.status_code == 200, upd_ref.text
        assert upd_ref.json()["ceiling_price"] == "32100.00"
        assert upd_ref.json()["floor_price"] == "27900.00"
    finally:
        client.delete(f"/api/admin/stocks/{stock_id}", headers=headers)


def test_admin_cancel_order_releases_reservations(client: TestClient, admin_token: str) -> None:
    """Cancelling a PENDING order as Admin releases blocked cash and blocked shares."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    cid, acc_id, email = _create_temp_customer(client, headers, initial_cash="100000000.00")
    sym = f"O{uuid.uuid4().hex[:4].upper()}"
    stock_res = client.post(
        "/api/admin/stocks",
        json={
            "stock_symbol": sym,
            "company_name": "CTCP Order Test",
            "exchange": "HOSE",
            "reference_price": "20000.00",
            "current_price": "20000.00",
        },
        headers=headers,
    )
    assert stock_res.status_code == 201, stock_res.text
    stock_id = stock_res.json()["stock_id"]
    try:
        login_res = client.post(
            "/api/auth/login",
            json={"email": email, "password": "Password@123"},
        )
        assert login_res.status_code == 200
        cust_headers = {"Authorization": f"Bearer {login_res.json()['access_token']}"}

        # 1. Place a PENDING BUY order (limit 19000 < market 20000)
        buy_res = client.post(
            f"/api/accounts/{acc_id}/orders",
            json={
                "client_order_id": str(uuid.uuid4()),
                "stock_symbol": sym,
                "order_type": "BUY",
                "order_kind": "LO",
                "quantity": 100,
                "order_price": 19000,
            },
            headers=cust_headers,
        )
        assert buy_res.status_code == 201, buy_res.text
        buy_order_id = buy_res.json()["order_id"]
        assert buy_res.json()["status"] == "PENDING"

        acc_mid = client.get(f"/api/admin/accounts/{acc_id}", headers=headers).json()
        assert Decimal(acc_mid["blocked_balance"]) > Decimal("0.00")

        # Admin cancels PENDING BUY order -> cash released
        cancel_buy = client.put(
            f"/api/admin/orders/{buy_order_id}",
            json={"status": "CANCELLED", "reject_reason": "Admin release check"},
            headers=headers,
        )
        assert cancel_buy.status_code == 200
        assert cancel_buy.json()["status"] == "CANCELLED"
        acc_after = client.get(f"/api/admin/accounts/{acc_id}", headers=headers).json()
        assert acc_after["blocked_balance"] == "0.00"
        assert acc_after["cash_balance"] == "100000000.00"

        # 2. Give customer shares and place a PENDING SELL order (limit 21000 > market 20000)
        port_res = client.post(
            "/api/admin/portfolios",
            json={
                "account_id": acc_id,
                "stock_symbol": sym,
                "quantity": 100,
                "available_quantity": 100,
                "blocked_quantity": 0,
                "average_price": "20000.00",
            },
            headers=headers,
        )
        assert port_res.status_code == 201, port_res.text
        port_id = port_res.json()["portfolio_id"]

        sell_res = client.post(
            f"/api/accounts/{acc_id}/orders",
            json={
                "client_order_id": str(uuid.uuid4()),
                "stock_symbol": sym,
                "order_type": "SELL",
                "order_kind": "LO",
                "quantity": 100,
                "order_price": 21000,
            },
            headers=cust_headers,
        )
        assert sell_res.status_code == 201, sell_res.text
        sell_order_id = sell_res.json()["order_id"]
        assert sell_res.json()["status"] == "PENDING"

        # Admin cancels PENDING SELL order -> shares released
        cancel_sell = client.put(
            f"/api/admin/orders/{sell_order_id}",
            json={"status": "CANCELLED"},
            headers=headers,
        )
        assert cancel_sell.status_code == 200
        ports = client.get(f"/api/admin/portfolios?account_id={acc_id}", headers=headers).json()
        assert ports["items"][0]["blocked_quantity"] == 0
        assert ports["items"][0]["available_quantity"] == 100

        # 3. Deleting an order with transactions returns 409 instead of 503
        matched_res = client.post(
            f"/api/accounts/{acc_id}/orders",
            json={
                "client_order_id": str(uuid.uuid4()),
                "stock_symbol": sym,
                "order_type": "BUY",
                "order_kind": "LO",
                "quantity": 100,
                "order_price": 20000,
            },
            headers=cust_headers,
        )
        assert matched_res.status_code == 201, matched_res.text
        matched_order_id = matched_res.json()["order_id"]
        assert matched_res.json()["status"] == "COMPLETED"

        del_matched = client.delete(f"/api/admin/orders/{matched_order_id}", headers=headers)
        assert del_matched.status_code == 409
        assert del_matched.json()["error"]["code"] == "ORDER_HAS_TRANSACTIONS"

        client.delete(f"/api/admin/portfolios/{port_id}", headers=headers)
    finally:
        client.delete(f"/api/admin/customers/{cid}", headers=headers)
        client.delete(f"/api/admin/stocks/{stock_id}", headers=headers)
