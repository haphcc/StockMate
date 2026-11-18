"""Real-time market quote integration using live Vietnamese financial data feeds.

Connects to verified live endpoints (SSI iBoard & DNSE) to provide real-time
quotes, market depth/volume, and intraday/daily candles with resilient fallback
to local database values when offline or outside market connectivity.
"""

import logging
import threading
import time
from collections.abc import Iterable
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Any

import httpx
from sqlalchemy.orm import Session

from app.models.stock import Stock
from app.models.stock_price_history import StockPriceHistory
from app.schemas.market import CandleResponse

logger = logging.getLogger(__name__)

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
REQUEST_TIMEOUT = 3.5
EXCHANGE_REQUEST_TIMEOUT = 5.0
EXCHANGE_CACHE_TTL_SECONDS = 15.0
VN_TZ = timezone(timedelta(hours=7))
TWO_PLACES = Decimal("0.01")

_exchange_cache_lock = threading.Lock()
_exchange_quote_cache: dict[str, tuple[float, dict[str, dict[str, Any]]]] = {}


def clear_live_quote_cache() -> None:
    """Clear in-memory SSI exchange quote cache (useful for tests/manual refresh)."""
    with _exchange_cache_lock:
        _exchange_quote_cache.clear()


def _to_positive_decimal(raw: Any) -> Decimal | None:
    if raw is None or raw == "":
        return None
    try:
        value = Decimal(str(raw))
    except Exception:
        return None
    return value if value > 0 else None


def _parse_trading_date(raw: Any) -> date | None:
    if not raw or not isinstance(raw, str):
        return None
    cleaned = raw.strip()
    try:
        if len(cleaned) == 8 and cleaned.isdigit():
            return datetime.strptime(cleaned, "%Y%m%d").date()
        return date.fromisoformat(cleaned[:10])
    except ValueError:
        return None


def _parse_ssi_quote(data: dict[str, Any], symbol: str) -> dict[str, Any] | None:
    """Normalize an SSI iBoard quote payload into our internal quote structure."""
    matched = data.get("matchedPrice") or data.get("priorClosePrice") or data.get("refPrice")
    ref = data.get("refPrice") or matched
    ceil = data.get("ceiling") or matched
    flr = data.get("floor") or matched
    vol = data.get("nmTotalTradedQty") or data.get("stockVol") or 0

    if not matched or not ref:
        return None

    quote: dict[str, Any] = {
        "symbol": symbol.strip().upper(),
        "current_price": Decimal(str(matched)),
        "reference_price": Decimal(str(ref)),
        "ceiling_price": Decimal(str(ceil)),
        "floor_price": Decimal(str(flr)),
        "total_volume": int(vol),
    }

    open_price = _to_positive_decimal(data.get("openPrice"))
    highest_price = _to_positive_decimal(data.get("highest"))
    lowest_price = _to_positive_decimal(data.get("lowest"))
    trading_value = _to_positive_decimal(data.get("nmTotalTradedValue"))
    trading_date = _parse_trading_date(data.get("tradingDate"))

    if open_price is not None:
        quote["open_price"] = open_price
    if highest_price is not None:
        quote["highest_price"] = highest_price
    if lowest_price is not None:
        quote["lowest_price"] = lowest_price
    if trading_value is not None:
        quote["trading_value"] = trading_value
    if trading_date is not None:
        quote["trading_date"] = trading_date

    return quote


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
            return _parse_ssi_quote(data, clean_symbol)
    except Exception as exc:
        logger.debug("Failed to fetch live quote for %s: %s", clean_symbol, exc)
        return None


def _fetch_single_exchange_quotes(exchange: str, *, use_cache: bool) -> dict[str, dict[str, Any]]:
    ex_key = exchange.strip().lower()
    now = time.monotonic()
    if use_cache:
        with _exchange_cache_lock:
            cached = _exchange_quote_cache.get(ex_key)
            if cached and (now - cached[0]) < EXCHANGE_CACHE_TTL_SECONDS:
                return cached[1]

    url = f"https://iboard-query.ssi.com.vn/stock/exchange/{ex_key}"
    quotes: dict[str, dict[str, Any]] = {}
    try:
        with httpx.Client(timeout=EXCHANGE_REQUEST_TIMEOUT, headers=HEADERS) as client:
            response = client.get(url)
            if response.status_code != 200:
                return quotes
            body = response.json()
            items = body.get("data")
            if not isinstance(items, list):
                return quotes
            for item in items:
                if not isinstance(item, dict):
                    continue
                raw_symbol = item.get("stockSymbol") or item.get("symbol")
                if not raw_symbol or not isinstance(raw_symbol, str):
                    continue
                parsed = _parse_ssi_quote(item, raw_symbol)
                if parsed is not None:
                    quotes[parsed["symbol"]] = parsed
        if quotes:
            with _exchange_cache_lock:
                _exchange_quote_cache[ex_key] = (time.monotonic(), quotes)
    except Exception as exc:
        logger.debug("Failed to fetch SSI exchange quotes for %s: %s", ex_key, exc)
    return quotes


def fetch_live_quotes_by_exchange(
    exchanges: Iterable[str] | None = None,
    *,
    use_cache: bool = True,
) -> dict[str, dict[str, Any]]:
    """Batch-fetch live quotes across Vietnamese exchanges (HOSE/HNX/UPCOM)."""
    targets = sorted(
        {
            ex.strip().lower()
            for ex in (exchanges or ("hose", "hnx", "upcom"))
            if ex and ex.strip().lower() in {"hose", "hnx", "upcom"}
        }
    )
    if not targets:
        return {}

    merged: dict[str, dict[str, Any]] = {}
    if len(targets) == 1:
        merged.update(_fetch_single_exchange_quotes(targets[0], use_cache=use_cache))
        return merged

    with ThreadPoolExecutor(max_workers=len(targets)) as executor:
        futures = [
            executor.submit(_fetch_single_exchange_quotes, ex, use_cache=use_cache)
            for ex in targets
        ]
        for future in futures:
            merged.update(future.result())
    return merged


def sync_stock_with_live_data(
    db: Session,
    stock: Stock,
    live_quote: dict[str, Any],
    *,
    commit: bool = True,
) -> Stock:
    """Update database stock entity with live quote and optionally commit."""
    stock.current_price = live_quote["current_price"]
    stock.reference_price = live_quote["reference_price"]
    stock.ceiling_price = live_quote["ceiling_price"]
    stock.floor_price = live_quote["floor_price"]
    stock.total_volume = live_quote["total_volume"]
    stock.updated_at = datetime.now(timezone.utc)
    if commit:
        db.commit()
        db.refresh(stock)
    return stock


def build_intraday_candle_from_quote(
    live_quote: dict[str, Any] | None,
) -> tuple[CandleResponse, Decimal | None] | None:
    """Build today's intraday OHLCV candle from an SSI live quote when OHLC is present."""
    if not live_quote:
        return None
    trading_date = live_quote.get("trading_date")
    if not isinstance(trading_date, date):
        return None

    close_price = _to_positive_decimal(live_quote.get("current_price"))
    open_price = _to_positive_decimal(live_quote.get("open_price"))
    volume = int(live_quote.get("total_volume") or 0)

    # Only synthesize an intraday candle once the session has actual price/open data.
    if close_price is None or (open_price is None and volume <= 0):
        return None

    effective_open = open_price or close_price
    high_raw = _to_positive_decimal(live_quote.get("highest_price")) or close_price
    low_raw = _to_positive_decimal(live_quote.get("lowest_price")) or close_price

    open_q = effective_open.quantize(TWO_PLACES)
    close_q = close_price.quantize(TWO_PLACES)
    high_q = max(open_q, close_q, high_raw.quantize(TWO_PLACES))
    low_q = min(open_q, close_q, low_raw.quantize(TWO_PLACES))

    trading_value = live_quote.get("trading_value")
    trading_value_q = (
        Decimal(str(trading_value)).quantize(TWO_PLACES) if trading_value is not None else None
    )

    candle = CandleResponse(
        recorded_date=trading_date,
        open_price=open_q,
        highest_price=high_q,
        lowest_price=low_q,
        close_price=close_q,
        trading_volume=max(volume, 0),
    )
    return candle, trading_value_q


def merge_candles_with_intraday(
    candles: list[CandleResponse] | None,
    live_quote: dict[str, Any] | None,
    *,
    limit: int | None = None,
) -> tuple[list[CandleResponse], dict[date, Decimal]]:
    """Merge historical DNSE candles with today's live SSI intraday candle if available."""
    by_date: dict[date, CandleResponse] = {}
    trading_values: dict[date, Decimal] = {}

    for candle in candles or []:
        by_date[candle.recorded_date] = candle

    intraday = build_intraday_candle_from_quote(live_quote)
    if intraday is not None:
        intraday_candle, trading_value = intraday
        by_date[intraday_candle.recorded_date] = intraday_candle
        if trading_value is not None:
            trading_values[intraday_candle.recorded_date] = trading_value

    ordered = [by_date[d] for d in sorted(by_date)]
    if limit is not None and len(ordered) > limit:
        ordered = ordered[-limit:]
    return ordered, trading_values


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
                open_dec = Decimal(str(round(open_p * 1000, 2))).quantize(TWO_PLACES)
                close_dec = Decimal(str(round(close_p * 1000, 2))).quantize(TWO_PLACES)
                high_dec = max(
                    open_dec,
                    close_dec,
                    Decimal(str(round(high_p * 1000, 2))).quantize(TWO_PLACES),
                )
                low_dec = min(
                    open_dec,
                    close_dec,
                    Decimal(str(round(low_p * 1000, 2))).quantize(TWO_PLACES),
                )
                candles.append(
                    CandleResponse(
                        recorded_date=datetime.fromtimestamp(ts, tz=VN_TZ).date(),
                        open_price=open_dec,
                        highest_price=high_dec,
                        lowest_price=low_dec,
                        close_price=close_dec,
                        trading_volume=max(int(vol), 0),
                    )
                )

            return candles[-limit:] if len(candles) >= limit else candles
    except Exception as exc:
        logger.debug("Failed to fetch live candles for %s: %s", clean_symbol, exc)
        return None


def upsert_price_history_candles(
    db: Session,
    stock: Stock,
    candles: list[CandleResponse],
    *,
    trading_values: dict[date, Decimal] | None = None,
    commit: bool = True,
) -> dict[str, int]:
    """Insert or update daily OHLCV rows in stock_price_history for a stock."""
    if not candles:
        return {"inserted": 0, "updated": 0, "total": 0}

    deduped = {candle.recorded_date: candle for candle in candles}
    existing_rows = (
        db.query(StockPriceHistory)
        .filter(
            StockPriceHistory.stock_id == stock.stock_id,
            StockPriceHistory.recorded_date.in_(list(deduped.keys())),
        )
        .all()
    )
    existing_by_date = {row.recorded_date: row for row in existing_rows}

    inserted = 0
    updated = 0
    for rec_date, candle in sorted(deduped.items()):
        open_q = Decimal(str(candle.open_price)).quantize(TWO_PLACES)
        close_q = Decimal(str(candle.close_price)).quantize(TWO_PLACES)
        high_q = max(open_q, close_q, Decimal(str(candle.highest_price)).quantize(TWO_PLACES))
        low_q = min(open_q, close_q, Decimal(str(candle.lowest_price)).quantize(TWO_PLACES))
        volume = max(int(candle.trading_volume), 0)
        if trading_values and rec_date in trading_values:
            value_q = trading_values[rec_date].quantize(TWO_PLACES)
        else:
            value_q = (close_q * Decimal(volume)).quantize(TWO_PLACES)

        row = existing_by_date.get(rec_date)
        if row is not None:
            row.open_price = open_q
            row.close_price = close_q
            row.highest_price = high_q
            row.lowest_price = low_q
            row.trading_volume = volume
            row.trading_value = value_q
            updated += 1
        else:
            db.add(
                StockPriceHistory(
                    stock_id=stock.stock_id,
                    recorded_date=rec_date,
                    open_price=open_q,
                    close_price=close_q,
                    highest_price=high_q,
                    lowest_price=low_q,
                    trading_volume=volume,
                    trading_value=value_q,
                )
            )
            inserted += 1

    if commit:
        db.commit()
    return {"inserted": inserted, "updated": updated, "total": inserted + updated}


def sync_stock_price_history(
    db: Session,
    stock: Stock,
    limit: int = 132,
    *,
    include_today_quote: bool = True,
    live_quote: dict[str, Any] | None = None,
    commit: bool = True,
) -> dict[str, Any]:
    """Fetch live daily candles (DNSE) + today's intraday quote (SSI) and upsert to DB."""
    quote = live_quote
    if include_today_quote and quote is None:
        quote = fetch_live_stock_quote(stock.stock_symbol)

    quote_synced = False
    if quote is not None:
        sync_stock_with_live_data(db, stock, quote, commit=False)
        quote_synced = True

    dnse_candles = fetch_live_candles(stock.stock_symbol, limit=limit)
    merged_candles, trading_values = merge_candles_with_intraday(
        dnse_candles,
        quote if include_today_quote else None,
        limit=limit,
    )
    stats = upsert_price_history_candles(
        db,
        stock,
        merged_candles,
        trading_values=trading_values,
        commit=commit,
    )
    if commit and quote_synced and not merged_candles:
        db.commit()
        db.refresh(stock)

    latest_date = merged_candles[-1].recorded_date if merged_candles else None
    return {
        "stock_symbol": stock.stock_symbol,
        "quote_synced": quote_synced,
        "inserted": stats["inserted"],
        "updated": stats["updated"],
        "synced_candles": stats["total"],
        "latest_date": latest_date,
    }


def sync_price_history_for_stocks(
    db: Session,
    stocks: list[Stock],
    limit: int = 132,
) -> dict[str, Any]:
    """Batch-sync live quotes and daily OHLCV history into PostgreSQL for given stocks."""
    if not stocks:
        return {
            "total_stocks": 0,
            "synced_stocks": 0,
            "failed_stocks": 0,
            "inserted_candles": 0,
            "updated_candles": 0,
            "latest_date": None,
            "synced_symbols": [],
            "failed_symbols": [],
        }

    # Fetch live quotes efficiently (batch exchange feed for bulk syncs).
    quotes_by_symbol: dict[str, dict[str, Any]] = {}
    if len(stocks) > 3:
        exchanges = {s.exchange for s in stocks if s.exchange}
        quotes_by_symbol = fetch_live_quotes_by_exchange(exchanges, use_cache=False)

    def _fetch_stock_payload(
        symbol: str,
    ) -> tuple[str, dict[str, Any] | None, list[CandleResponse] | None]:
        quote = quotes_by_symbol.get(symbol)
        if quote is None:
            quote = fetch_live_stock_quote(symbol)
        candles = fetch_live_candles(symbol, limit=limit)
        return symbol, quote, candles

    fetched: dict[str, tuple[dict[str, Any] | None, list[CandleResponse] | None]] = {}
    if len(stocks) == 1:
        sym, quote, candles = _fetch_stock_payload(stocks[0].stock_symbol)
        fetched[sym] = (quote, candles)
    else:
        max_workers = min(8, len(stocks))
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            for sym, quote, candles in executor.map(
                lambda s: _fetch_stock_payload(s.stock_symbol), stocks
            ):
                fetched[sym] = (quote, candles)

    synced_symbols: list[str] = []
    failed_symbols: list[str] = []
    inserted_total = 0
    updated_total = 0
    latest_date: date | None = None

    for stock in stocks:
        quote, dnse_candles = fetched.get(stock.stock_symbol, (None, None))
        if quote is not None:
            sync_stock_with_live_data(db, stock, quote, commit=False)

        merged_candles, trading_values = merge_candles_with_intraday(
            dnse_candles,
            quote,
            limit=limit,
        )
        if merged_candles:
            stats = upsert_price_history_candles(
                db,
                stock,
                merged_candles,
                trading_values=trading_values,
                commit=False,
            )
            inserted_total += stats["inserted"]
            updated_total += stats["updated"]
            stock_latest = merged_candles[-1].recorded_date
            if latest_date is None or stock_latest > latest_date:
                latest_date = stock_latest
            synced_symbols.append(stock.stock_symbol)
        elif quote is not None:
            synced_symbols.append(stock.stock_symbol)
        else:
            failed_symbols.append(stock.stock_symbol)

    db.commit()

    return {
        "total_stocks": len(stocks),
        "synced_stocks": len(synced_symbols),
        "failed_stocks": len(failed_symbols),
        "inserted_candles": inserted_total,
        "updated_candles": updated_total,
        "latest_date": latest_date,
        "synced_symbols": synced_symbols,
        "failed_symbols": failed_symbols,
    }


def sync_all_active_stocks(
    db: Session,
    symbols: list[str] | None = None,
    *,
    include_history: bool = False,
    history_limit: int = 132,
) -> dict[str, Any]:
    """Batch-sync live prices (and optionally daily candle history) into PostgreSQL."""
    query = db.query(Stock).filter(Stock.status == "ACTIVE")
    if symbols:
        clean = [s.strip().upper() for s in symbols]
        query = query.filter(Stock.stock_symbol.in_(clean))

    stocks = query.all()
    if include_history:
        summary = sync_price_history_for_stocks(db, stocks, limit=history_limit)
        return {
            "total": summary["total_stocks"],
            "synced_count": summary["synced_stocks"],
            "failed_count": summary["failed_stocks"],
            "synced_symbols": summary["synced_symbols"],
            "failed_symbols": summary["failed_symbols"],
            "candles_synced": summary["inserted_candles"] + summary["updated_candles"],
        }

    batch_quotes: dict[str, dict[str, Any]] = {}
    if len(stocks) > 5:
        exchanges = {s.exchange for s in stocks if s.exchange}
        batch_quotes = fetch_live_quotes_by_exchange(exchanges, use_cache=False)

    synced = []
    failed = []

    for stock in stocks:
        quote = batch_quotes.get(stock.stock_symbol) or fetch_live_stock_quote(stock.stock_symbol)
        if quote:
            sync_stock_with_live_data(db, stock, quote, commit=(len(stocks) <= 5))
            synced.append(stock.stock_symbol)
        else:
            failed.append(stock.stock_symbol)

    if len(stocks) > 5 and synced:
        db.commit()

    return {
        "total": len(stocks),
        "synced_count": len(synced),
        "failed_count": len(failed),
        "synced_symbols": synced,
        "failed_symbols": failed,
        "candles_synced": 0,
    }
