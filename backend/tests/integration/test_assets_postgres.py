"""LB CP2/3: ownership, valuation and assets refreshed after real trading APIs."""

from datetime import date
from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.investment_account import InvestmentAccount
from app.models.portfolio import Portfolio
from app.models.stock import Stock
from app.services.settlement_service import process_share_settlements

pytestmark = pytest.mark.integration


def assets(client, account_id, headers):
    response = client.get(f"/api/accounts/{account_id}/assets", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def holdings(client, account_id, headers):
    response = client.get(f"/api/accounts/{account_id}/portfolio", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def place(client, account_id, headers, side="BUY", price="100000.00"):
    response = client.post(
        f"/api/accounts/{account_id}/orders",
        headers=headers,
        json={
            "client_order_id": str(uuid4()),
            "stock_symbol": "FPT",
            "order_type": side,
            "order_kind": "LO",
            "quantity": 100,
            "order_price": price,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_empty_account_assets_are_exact_and_zero_cost_is_null(cp_client, cp_user):
    _, account_id, headers = cp_user
    data = assets(cp_client, account_id, headers)
    assert data["cash_balance"] == data["total_asset_value"] == "1000000000.00"
    assert data["blocked_balance"] == data["stock_value"] == data["total_profit_loss"] == "0.00"
    assert data["profit_loss_percent"] is None
    assert holdings(cp_client, account_id, headers) == []


def test_live_valuation_ignores_stale_cached_values_and_maps_flat_holdings(
    cp_client,
    cp_user,
    add_stock,
    pg_engine,
):
    _, account_id, headers = cp_user
    stock_id = add_stock()
    with Session(pg_engine) as db:
        account = db.get(InvestmentAccount, account_id)
        account.cash_balance = Decimal("123.45")
        account.blocked_balance = Decimal("67.89")
        account.total_asset_value = Decimal("1.00")  # Deliberately stale cached NAV.
        db.add(
            Portfolio(
                account_id=account_id,
                stock_id=stock_id,
                quantity=100,
                available_quantity=50,
                blocked_quantity=20,
                average_price="90000.00",
                current_value="1.00",
                profit_loss="1.00",
            )
        )
        db.commit()
    data = assets(cp_client, account_id, headers)
    assert data["stock_value"] == "10000000.00" and data["total_asset_value"] == "10000191.34"
    assert data["total_profit_loss"] == "1000000.00" and data["profit_loss_percent"] == "11.11"
    row = holdings(cp_client, account_id, headers)[0]
    assert "stock" not in row
    assert row["stock_symbol"] == "FPT" and row["quantity"] == 100
    assert row["pending_quantity"] == 30 and row["blocked_quantity"] == 20
    assert row["current_value"] == "10000000.00" and row["profit_loss"] == "1000000.00"
    with Session(pg_engine) as db:
        db.get(Stock, stock_id).current_price = Decimal("95000.00")
        db.commit()
    updated = assets(cp_client, account_id, headers)
    assert updated["stock_value"] == "9500000.00" and updated["total_asset_value"] == "9500191.34"
    assert updated["total_profit_loss"] == "500000.00" and updated["profit_loss_percent"] == "5.56"
    assert holdings(cp_client, account_id, headers)[0]["market_price"] == "95000.00"


def test_account_ownership_and_switching(cp_client, cp_user, pg_engine):
    customer_id, account_id, headers = cp_user
    with Session(pg_engine) as db:
        second = InvestmentAccount(
            customer_id=customer_id,
            account_number="LB-MARGIN",
            account_type="MARGIN",
            cash_balance="25.01",
            status="SUSPENDED",
        )
        db.add(second)
        db.commit()
        second_id = second.account_id
    assert assets(cp_client, second_id, headers)["cash_balance"] == "25.01"
    assert assets(cp_client, account_id, headers)["cash_balance"] == "1000000000.00"
    stranger = cp_client.post(
        "/api/auth/register",
        json={
            "full_name": "Other",
            "email": "other@example.com",
            "phone_number": "0907654321",
            "password": "Matkhau@123",
        },
    ).json()
    other_headers = {"Authorization": "Bearer " + stranger["access_token"]}
    for suffix in ["assets", "portfolio"]:
        foreign = cp_client.get(f"/api/accounts/{account_id}/{suffix}", headers=other_headers)
        missing = cp_client.get(f"/api/accounts/999999/{suffix}", headers=other_headers)
        assert foreign.status_code == missing.status_code == 404
        assert foreign.json() == missing.json()
        assert cp_client.get(f"/api/accounts/{account_id}/{suffix}").status_code == 401
        assert cp_client.get(f"/api/accounts/0/{suffix}", headers=headers).status_code == 422
        assert cp_client.get(f"/api/accounts/{2**63}/{suffix}", headers=headers).status_code == 422


def test_zero_cost_percentage_and_exclude_empty_holdings(cp_client, cp_user, add_stock, pg_engine):
    _, account_id, headers = cp_user
    first, second = add_stock(), add_stock("AAA")
    with Session(pg_engine) as db:
        db.add_all(
            [
                Portfolio(
                    account_id=account_id,
                    stock_id=first,
                    quantity=10,
                    available_quantity=10,
                    average_price="0.00",
                ),
                Portfolio(
                    account_id=account_id, stock_id=second, quantity=0, average_price="90000.00"
                ),
            ]
        )
        db.commit()
    rows = holdings(cp_client, account_id, headers)
    assert len(rows) == 1 and rows[0]["profit_loss_percent"] is None
    assert assets(cp_client, account_id, headers)["profit_loss_percent"] is None


def test_pending_buy_cancel_restores_assets_once(cp_client, cp_user, add_stock):
    _, account_id, headers = cp_user
    add_stock(current_price="105000.00")
    order = place(cp_client, account_id, headers)
    assert order["status"] == "PENDING"
    data = assets(cp_client, account_id, headers)
    assert data["cash_balance"] == "989985000.00" and data["blocked_balance"] == "10015000.00"
    assert data["total_asset_value"] == "1000000000.00"
    for _ in range(2):
        cancel = cp_client.delete(f"/api/orders/{order['order_id']}", headers=headers)
        assert cancel.status_code == 200 and cancel.json()["status"] == "CANCELLED"
    data = assets(cp_client, account_id, headers)
    assert data["cash_balance"] == "1000000000.00" and data["blocked_balance"] == "0.00"
    assert holdings(cp_client, account_id, headers) == []


def test_shared_auth_isolates_orders_transactions_cancel_and_notifications(
    cp_client,
    cp_user,
    add_stock,
):
    _, account_id, headers = cp_user
    add_stock(current_price="105000.00")
    order = place(cp_client, account_id, headers)
    notification_id = cp_client.get("/api/notifications", headers=headers).json()["items"][0][
        "notification_id"
    ]
    other = cp_client.post(
        "/api/auth/register",
        json={
            "full_name": "Other",
            "email": "other@example.com",
            "phone_number": "0907654321",
            "password": "Matkhau@123",
        },
    ).json()
    other_headers = {"Authorization": "Bearer " + other["access_token"]}
    for path in [f"/api/accounts/{account_id}/orders", f"/api/accounts/{account_id}/transactions"]:
        assert cp_client.get(path, headers=other_headers).status_code == 404
    assert (
        cp_client.delete(f"/api/orders/{order['order_id']}", headers=other_headers).status_code
        == 404
    )
    assert (
        cp_client.post(
            f"/api/notifications/{notification_id}/read", headers=other_headers
        ).status_code
        == 404
    )
    assert cp_client.get("/api/notifications", headers=other_headers).json()["items"] == []
    assert assets(cp_client, account_id, headers)["blocked_balance"] == "10015000.00"


def test_buy_reprice_settle_sell_and_read_fresh_assets(cp_client, cp_user, add_stock, pg_engine):
    _, account_id, headers = cp_user
    stock_id = add_stock(current_price="99000.00")
    order = place(cp_client, account_id, headers)
    assert order["status"] == "COMPLETED"
    data = assets(cp_client, account_id, headers)
    assert data["cash_balance"] == "990085150.00" and data["blocked_balance"] == "0.00"
    assert data["stock_value"] == "9900000.00" and data["total_asset_value"] == "999985150.00"
    row = holdings(cp_client, account_id, headers)[0]
    assert row["available_quantity"] == 0 and row["pending_quantity"] == 100
    with Session(pg_engine) as db:
        db.get(Stock, stock_id).current_price = Decimal("105000.00")
        db.commit()
        process_share_settlements(db, as_of_date=date(2030, 1, 1))
        process_share_settlements(db, as_of_date=date(2030, 1, 1))
    data = assets(cp_client, account_id, headers)
    assert data["stock_value"] == "10500000.00" and data["total_profit_loss"] == "600000.00"
    row = holdings(cp_client, account_id, headers)[0]
    assert row["available_quantity"] == 100 and row["pending_quantity"] == 0
    pending_sell = place(cp_client, account_id, headers, side="SELL", price="106000.00")
    assert pending_sell["status"] == "PENDING"
    row = holdings(cp_client, account_id, headers)[0]
    assert row["available_quantity"] == 0 and row["blocked_quantity"] == 100
    assert row["pending_quantity"] == 0
    cp_client.delete(f"/api/orders/{pending_sell['order_id']}", headers=headers)
    sold = place(cp_client, account_id, headers, side="SELL", price="104000.00")
    assert sold["status"] == "COMPLETED"
    assert holdings(cp_client, account_id, headers) == []
    data = assets(cp_client, account_id, headers)
    assert data["cash_balance"] == "1000558900.00" and data["stock_value"] == "0.00"
    assert data["total_asset_value"] == data["cash_balance"]
    assert (
        cp_client.get(f"/api/accounts/{account_id}/transactions", headers=headers).json()["total"]
        == 2
    )
