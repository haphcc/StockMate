"""Unit tests for real-time market quote and candle integration."""

from datetime import date, datetime, timezone
from decimal import Decimal
from unittest.mock import MagicMock, patch

from app.models.stock import Stock
from app.models.stock_price_history import StockPriceHistory
from app.schemas.market import CandleResponse
from app.services.realtime_market import (
    build_intraday_candle_from_quote,
    clear_live_quote_cache,
    fetch_live_candles,
    fetch_live_quotes_by_exchange,
    fetch_live_stock_quote,
    merge_candles_with_intraday,
    sync_all_active_stocks,
    sync_stock_with_live_data,
    upsert_price_history_candles,
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


def test_build_and_merge_intraday_candle_from_ssi_quote():
    historical = [
        CandleResponse(
            recorded_date=date(2026, 11, 17),
            open_price=Decimal("31100.00"),
            close_price=Decimal("31000.00"),
            highest_price=Decimal("31200.00"),
            lowest_price=Decimal("30900.00"),
            trading_volume=1500000,
        )
    ]
    live_quote = {
        "symbol": "BID",
        "current_price": Decimal("30550"),
        "reference_price": Decimal("31000"),
        "ceiling_price": Decimal("33150"),
        "floor_price": Decimal("28850"),
        "total_volume": 2158900,
        "open_price": Decimal("30750"),
        "highest_price": Decimal("30800"),
        "lowest_price": Decimal("30500"),
        "trading_value": Decimal("66075600000"),
        "trading_date": date(2026, 11, 18),
    }

    intraday = build_intraday_candle_from_quote(live_quote)
    assert intraday is not None
    candle, trading_val = intraday
    assert candle.recorded_date == date(2026, 11, 18)
    assert candle.open_price == Decimal("30750.00")
    assert candle.close_price == Decimal("30550.00")
    assert trading_val == Decimal("66075600000.00")

    merged, values = merge_candles_with_intraday(historical, live_quote, limit=2)
    assert [c.recorded_date for c in merged] == [date(2026, 11, 17), date(2026, 11, 18)]
    assert values[date(2026, 11, 18)] == Decimal("66075600000.00")


def test_upsert_price_history_candles_inserts_and_updates():
    db = MagicMock()
    stock = Stock(stock_id=7, stock_symbol="BID")
    existing = StockPriceHistory(
        price_history_id=10,
        stock_id=7,
        recorded_date=date(2026, 11, 17),
        open_price=Decimal("30000.00"),
        close_price=Decimal("30000.00"),
        highest_price=Decimal("30000.00"),
        lowest_price=Decimal("30000.00"),
        trading_volume=100,
        trading_value=Decimal("3000000.00"),
    )
    query_mock = MagicMock()
    query_mock.filter.return_value = query_mock
    query_mock.all.return_value = [existing]
    db.query.return_value = query_mock

    candles = [
        CandleResponse(
            recorded_date=date(2026, 11, 17),
            open_price=Decimal("31100.00"),
            close_price=Decimal("31000.00"),
            highest_price=Decimal("31200.00"),
            lowest_price=Decimal("30900.00"),
            trading_volume=1500000,
        ),
        CandleResponse(
            recorded_date=date(2026, 11, 18),
            open_price=Decimal("30750.00"),
            close_price=Decimal("30550.00"),
            highest_price=Decimal("30800.00"),
            lowest_price=Decimal("30500.00"),
            trading_volume=2158900,
        ),
    ]

    stats = upsert_price_history_candles(
        db,
        stock,
        candles,
        trading_values={date(2026, 11, 18): Decimal("66075600000.00")},
    )
    assert stats == {"inserted": 1, "updated": 1, "total": 2}
    assert existing.close_price == Decimal("31000.00")
    assert existing.trading_volume == 1500000
    assert db.add.call_count == 1
    assert db.commit.called


def test_fetch_live_quotes_by_exchange_parses_and_caches():
    clear_live_quote_cache()
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "code": "SUCCESS",
        "data": [
            {
                "stockSymbol": "BID",
                "matchedPrice": 30550,
                "refPrice": 31000,
                "ceiling": 33150,
                "floor": 28850,
                "nmTotalTradedQty": 2158900,
                "openPrice": 30750,
                "highest": 30800,
                "lowest": 30500,
                "tradingDate": "20261118",
            }
        ],
    }

    with patch("httpx.Client.get", return_value=mock_response) as mock_get:
        first = fetch_live_quotes_by_exchange(["HOSE"])
        second = fetch_live_quotes_by_exchange(["HOSE"])
        assert "BID" in first
        assert first["BID"]["current_price"] == Decimal("30550")
        assert first["BID"]["trading_date"] == date(2026, 11, 18)
        assert second["BID"]["current_price"] == Decimal("30550")
        assert mock_get.call_count == 1
    clear_live_quote_cache()
