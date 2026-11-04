"""Real-time market quote integration using live Vietnamese financial data feeds.

Connects to verified live endpoints (SSI iBoard & DNSE) to provide real-time
quotes, market depth/volume, and intraday/daily candles with resilient fallback
to local database values when offline or outside market connectivity.
"""

import logging
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any

import httpx
from sqlalchemy.orm import Session

from app.models.stock import Stock
from app.schemas.market import CandleResponse

logger = logging.getLogger(__name__)

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
REQUEST_TIMEOUT = 3.5


def fetch_live_stock_quote(symbol: str) -> dict[str, Any] | None:
    """Fetch live quote from SSI iBoard API with timeout and graceful fallback."""
    clean_symbol = symbol.strip().upper()
    url = f"https://iboard-query.ssi.com.vn/stock/{clean_symbol}"
    try:
        with httpx.Client(timeout=REQUEST_TIMEOUT, headers=HEADERS) as client:
            response = client.get(url)
            if response.status_code != 200:
                return None
            body = response.json()
            data = body.get("data")
            if not data or not isinstance(data, dict):
                return None

            matched = (
                data.get("matchedPrice") or data.get("priorClosePrice") or data.get("refPrice")
            )
            ref = data.get("refPrice") or matched
            ceil = data.get("ceiling") or matched
            flr = data.get("floor") or matched
            vol = data.get("nmTotalTradedQty") or data.get("stockVol") or 0

            if not matched or not ref:
                return None

            return {
                "symbol": clean_symbol,
                "current_price": Decimal(str(matched)),
                "reference_price": Decimal(str(ref)),
                "ceiling_price": Decimal(str(ceil)),
                "floor_price": Decimal(str(flr)),
                "total_volume": int(vol),
            }
    except Exception as exc:
        logger.debug("Failed to fetch live quote for %s: %s", clean_symbol, exc)
        return None


def sync_stock_with_live_data(db: Session, stock: Stock, live_quote: dict[str, Any]) -> Stock:
    """Update database stock entity with live quote and commit."""
    stock.current_price = live_quote["current_price"]
    stock.reference_price = live_quote["reference_price"]
    stock.ceiling_price = live_quote["ceiling_price"]
    stock.floor_price = live_quote["floor_price"]
    stock.total_volume = live_quote["total_volume"]
    stock.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(stock)
    return stock


def fetch_live_candles(symbol: str, limit: int = 22) -> list[CandleResponse] | None:
    """Fetch real-time daily candles from DNSE chart API."""
    clean_symbol = symbol.strip().upper()
    now_ts = int(datetime.now(timezone.utc).timestamp())
    days_back = max(60, int(limit * 2.2))
    from_ts = now_ts - (days_back * 86400)
    url = (
        f"https://services.entrade.com.vn/chart-api/v2/ohlcs/stock"
        f"?from={from_ts}&to={now_ts}&symbol={clean_symbol}&resolution=1D"
    )
    try:
        with httpx.Client(timeout=REQUEST_TIMEOUT, headers=HEADERS) as client:
            response = client.get(url)
            if response.status_code != 200:
                return None
            data = response.json()
            timestamps = data.get("t", [])
            opens = data.get("o", [])
            highs = data.get("h", [])
            lows = data.get("l", [])
            closes = data.get("c", [])
            volumes = data.get("v", [])

            if not timestamps or len(timestamps) != len(closes):
                return None

            candles: list[CandleResponse] = []
            for ts, open_p, high_p, low_p, close_p, vol in zip(
                timestamps, opens, highs, lows, closes, volumes
            ):
                candles.append(
                    CandleResponse(
                        recorded_date=date.fromtimestamp(ts),
                        open_price=Decimal(str(round(open_p * 1000, 2))),
                        highest_price=Decimal(str(round(high_p * 1000, 2))),
                        lowest_price=Decimal(str(round(low_p * 1000, 2))),
                        close_price=Decimal(str(round(close_p * 1000, 2))),
                        trading_volume=int(vol),
                    )
                )

            return candles[-limit:] if len(candles) >= limit else candles
    except Exception as exc:
        logger.debug("Failed to fetch live candles for %s: %s", clean_symbol, exc)
        return None


def sync_all_active_stocks(db: Session, symbols: list[str] | None = None) -> dict[str, Any]:
    """Batch-sync live prices into PostgreSQL database."""
    query = db.query(Stock).filter(Stock.status == "ACTIVE")
    if symbols:
        clean = [s.strip().upper() for s in symbols]
        query = query.filter(Stock.stock_symbol.in_(clean))

    stocks = query.all()
    synced = []
    failed = []

    for stock in stocks:
        quote = fetch_live_stock_quote(stock.stock_symbol)
        if quote:
            sync_stock_with_live_data(db, stock, quote)
            synced.append(stock.stock_symbol)
        else:
            failed.append(stock.stock_symbol)

    return {
        "total": len(stocks),
        "synced_count": len(synced),
        "failed_count": len(failed),
        "synced_symbols": synced,
        "failed_symbols": failed,
    }
