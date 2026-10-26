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
