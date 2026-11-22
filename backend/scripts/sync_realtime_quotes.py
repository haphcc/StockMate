"""Sync real-time stock quotes (SSI iBoard) and daily candles (DNSE) into PostgreSQL."""

import argparse
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

from app.db.session import SessionLocal  # noqa: E402
from app.services.realtime_market import sync_all_active_stocks  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Sync real-time stock prices and daily OHLCV history into DB."
    )
    parser.add_argument(
        "--symbols",
        type=str,
        default=None,
        help="Comma-separated stock symbols (e.g. 'SSI,VNM,HPG,FPT,TCB'). Default: all active.",
    )
    parser.add_argument(
        "--quotes-only",
        action="store_true",
        help="Only sync current quotes into stocks table without syncing stock_price_history.",
    )
    parser.add_argument(
        "--history-limit",
        type=int,
        default=132,
        help="Maximum number of daily candles to upsert per stock (default: 132).",
    )
    args = parser.parse_args()

    symbols = [s.strip().upper() for s in args.symbols.split(",")] if args.symbols else None
    include_history = not args.quotes_only

    db = SessionLocal()
    try:
        mode = "quotes + price history" if include_history else "quotes only"
        print(f"Starting real-time market sync ({mode})...")
        result = sync_all_active_stocks(
            db,
            symbols,
            include_history=include_history,
            history_limit=args.history_limit,
        )
        print(f"Total processed: {result['total']}")
        print(f"Successfully synced: {result['synced_count']}")
        if include_history:
            print(f"Candles inserted/updated: {result.get('candles_synced', 0)}")
        if result["failed_count"]:
            print(f"Failed to sync: {result['failed_count']}")
        print("Real-time market sync completed.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
