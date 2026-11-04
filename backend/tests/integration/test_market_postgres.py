"""LB CP2: quote contract, literal search, stable paging and candle windows."""

from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

import pytest
from sqlalchemy.orm import Session

from app.models.stock import Stock
from app.models.stock_price_history import StockPriceHistory

pytestmark = pytest.mark.integration


def test_market_page_filters_search_and_stable_sort(cp_client, cp_user, add_stock):
    _, _, headers = cp_user
    add_stock("AAA", total_volume=100, company_name="Công ty Việt 100%_A")
    add_stock("BBB", total_volume=500, exchange="HNX")
    add_stock("CCC", total_volume=100, exchange="UPCOM")
    page = cp_client.get("/api/market/board?page_size=2", headers=headers)
    assert page.status_code == 200
    data = page.json()
    assert data["total"] == 3 and data["page"] == 1 and data["page_size"] == 2
    assert [item["stock_symbol"] for item in data["items"]] == ["BBB", "AAA"]
    assert (
        cp_client.get("/api/market/board?page=2&page_size=2", headers=headers).json()["items"][0][
            "stock_symbol"
        ]
        == "CCC"
    )
    beyond = cp_client.get("/api/market/board?page=99", headers=headers).json()
    assert beyond["items"] == [] and beyond["total"] == 3
    for exchange, symbol in [("HOSE", "AAA"), ("HNX", "BBB"), ("UPCOM", "CCC")]:
        assert (
            cp_client.get(
                "/api/market/board", params={"exchange": exchange}, headers=headers
            ).json()["items"][0]["stock_symbol"]
            == symbol
        )
    for query in ["aaa", "Công ty Việt", "cÔNG TY vIỆT", "%_", "100%_A"]:
        result = cp_client.get("/api/market/board", params={"q": query}, headers=headers).json()
        assert result["total"] == 1 and result["items"][0]["stock_symbol"] == "AAA"
    empty = cp_client.get("/api/market/board?q=not-found", headers=headers).json()
    assert empty["items"] == [] and empty["total"] == 0


@pytest.mark.parametrize("query", ["page=0", "page_size=0", "page_size=101", "exchange=NYSE"])
def test_market_rejects_invalid_paging_and_exchange(cp_client, cp_user, query):
    response = cp_client.get("/api/market/board?" + query, headers=cp_user[2])
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


@pytest.mark.parametrize(
    "price,state",
    [
        ("107000.00", "CEILING"),
        ("93000.00", "FLOOR"),
        ("100000.00", "REFERENCE"),
        ("101000.00", "UP"),
        ("99000.00", "DOWN"),
    ],
)
def test_quote_price_states_money_and_utc(cp_client, cp_user, add_stock, pg_engine, price, state):
    stock_id = add_stock(current_price=price)
    with Session(pg_engine) as db:
        db.get(Stock, stock_id).updated_at = datetime(
            2026, 11, 4, 15, tzinfo=timezone(timedelta(hours=7))
        )
        db.commit()
    response = cp_client.get("/api/stocks/fpt", headers=cp_user[2])
    assert response.status_code == 200
    quote = response.json()
    assert quote["price_state"] == state and quote["current_price"] == price
    assert quote["data_source"] == "DEMO" and quote["is_stale"] is True
    assert quote["updated_at"] == "2026-11-04T08:00:00Z"
    assert isinstance(quote["total_volume"], int)
    assert quote["change_percent"] == f"{(Decimal(price) - 100000) / 1000:.2f}"


@pytest.mark.parametrize("chart_range,limit", [("1M", 22), ("3M", 66), ("6M", 132)])
def test_chart_returns_recent_sessions_oldest_first(
    cp_client,
    cp_user,
    add_stock,
    pg_engine,
    chart_range,
    limit,
):
    stock_id = add_stock()
    first_day = date(2026, 1, 1)
    with Session(pg_engine) as db:
        db.add_all(
            [
                StockPriceHistory(
                    stock_id=stock_id,
                    recorded_date=first_day + timedelta(days=i),
                    open_price=Decimal("99000.00"),
                    close_price=Decimal("100000.00"),
                    highest_price=Decimal("101000.00"),
                    lowest_price=Decimal("98000.00"),
                    trading_volume=i,
                )
                for i in range(140)
            ]
        )
        db.commit()
    response = cp_client.get(f"/api/stocks/FPT/chart?range={chart_range}", headers=cp_user[2])
    assert response.status_code == 200
    candles = response.json()
    assert len(candles) == limit
    assert candles[0]["recorded_date"] == (first_day + timedelta(days=140 - limit)).isoformat()
    assert candles[-1]["recorded_date"] == (first_day + timedelta(days=139)).isoformat()
    assert candles[-1]["open_price"] == "99000.00"
    assert isinstance(candles[-1]["trading_volume"], int)


def test_missing_stock_empty_chart_and_auth(cp_client, cp_user, add_stock):
    headers = cp_user[2]
    for path in ["/api/market/board", "/api/stocks/FPT", "/api/stocks/FPT/chart"]:
        assert cp_client.get(path).status_code == 401
    for path in ["/api/stocks/NOPE", "/api/stocks/NOPE/chart"]:
        assert cp_client.get(path, headers=headers).status_code == 404
    add_stock()
    assert cp_client.get("/api/stocks/FPT/chart", headers=headers).json() == []
    assert cp_client.get("/api/stocks/FPT/chart?range=1Y", headers=headers).status_code == 422


def test_zero_reference_price_is_explicit(cp_client, cp_user, add_stock):
    add_stock(current_price="0.00", reference_price="0.00")
    quote = cp_client.get("/api/stocks/FPT", headers=cp_user[2]).json()
    assert quote["change_percent"] is None and quote["price_state"] == "REFERENCE"
