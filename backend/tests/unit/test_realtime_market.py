"""Unit tests for real-time market quote and candle integration."""

from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import MagicMock, patch

from app.models.stock import Stock
from app.services.realtime_market import (
    fetch_live_candles,
    fetch_live_stock_quote,
    sync_all_active_stocks,
    sync_stock_with_live_data,
)


def test_sync_stock_with_live_data():
    db = MagicMock()
    stock = Stock(
        stock_id=1,
        stock_symbol="VNM",
        company_name="Vinamilk",
        exchange="HOSE",
        current_price=Decimal("50000.00"),
        reference_price=Decimal("50000.00"),
        ceiling_price=Decimal("53500.00"),
        floor_price=Decimal("46500.00"),
        total_volume=1000,
        status="ACTIVE",
        updated_at=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )

    live_quote = {
        "symbol": "VNM",
        "current_price": Decimal("57400.00"),
        "reference_price": Decimal("56300.00"),
        "ceiling_price": Decimal("60200.00"),
        "floor_price": Decimal("52400.00"),
        "total_volume": 3430600,
    }

    sync_stock_with_live_data(db, stock, live_quote)

    assert stock.current_price == Decimal("57400.00")
    assert stock.reference_price == Decimal("56300.00")
    assert stock.ceiling_price == Decimal("60200.00")
    assert stock.floor_price == Decimal("52400.00")
    assert stock.total_volume == 3430600
    assert db.commit.called
    assert db.refresh.called


def test_fetch_live_stock_quote_fallback_on_error():
    with patch("httpx.Client.get", side_effect=Exception("Network error")):
        quote = fetch_live_stock_quote("VNM")
        assert quote is None


def test_fetch_live_candles_fallback_on_error():
    with patch("httpx.Client.get", side_effect=Exception("Network error")):
        candles = fetch_live_candles("VNM", limit=22)
        assert candles is None


def test_fetch_live_stock_quote_mocked_success():
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "code": "SUCCESS",
        "data": {
            "matchedPrice": 57400,
            "refPrice": 56300,
            "ceiling": 60200,
            "floor": 52400,
            "nmTotalTradedQty": 3430600,
        },
    }

    with patch("httpx.Client.get", return_value=mock_response):
        quote = fetch_live_stock_quote("VNM")
        assert quote is not None
        assert quote["current_price"] == Decimal("57400")
        assert quote["reference_price"] == Decimal("56300")
        assert quote["total_volume"] == 3430600


def test_fetch_live_candles_mocked_success():
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "t": [1793671200, 1793757600],
        "o": [56.5, 56.6],
        "h": [57.0, 57.5],
        "l": [56.0, 56.4],
        "c": [56.3, 57.4],
        "v": [1905600, 3430600],
    }

    with patch("httpx.Client.get", return_value=mock_response):
        candles = fetch_live_candles("VNM", limit=2)
        assert candles is not None
        assert len(candles) == 2
        assert candles[-1].close_price == Decimal("57400.00")
        assert candles[-1].model_dump(mode="json")["close_price"] == "57400.00"
        assert candles[-1].trading_volume == 3430600


def test_sync_all_active_stocks():
    db = MagicMock()
    stock1 = Stock(
        stock_id=1,
        stock_symbol="VNM",
        status="ACTIVE",
        current_price=Decimal("50000"),
        reference_price=Decimal("50000"),
        ceiling_price=Decimal("53500"),
        floor_price=Decimal("46500"),
        total_volume=1000,
    )
    query_mock = MagicMock()
    query_mock.filter.return_value = query_mock
    query_mock.all.return_value = [stock1]
    db.query.return_value = query_mock

    mock_quote = {
        "symbol": "VNM",
        "current_price": Decimal("57400"),
        "reference_price": Decimal("56300"),
        "ceiling_price": Decimal("60200"),
        "floor_price": Decimal("52400"),
        "total_volume": 3430600,
    }

    with patch("app.services.realtime_market.fetch_live_stock_quote", return_value=mock_quote):
        res = sync_all_active_stocks(db, ["VNM"])
        assert res["total"] == 1
        assert res["synced_count"] == 1
        assert "VNM" in res["synced_symbols"]
