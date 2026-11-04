"""Sync real-time stock prices from live market feed (SSI iBoard) into PostgreSQL."""

import argparse
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

from app.db.session import SessionLocal  # noqa: E402
from app.services.realtime_market import sync_all_active_stocks  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync real-time stock prices into DB.")
    parser.add_argument(
        "--symbols",
        type=str,
        default=None,
        help="Comma-separated stock symbols (e.g. 'SSI,VNM,HPG,FPT,TCB'). Default: all active.",
    )
    args = parser.parse_args()

    symbols = [s.strip().upper() for s in args.symbols.split(",")] if args.symbols else None

    db = SessionLocal()
    try:
        print("Starting real-time market sync...")
        result = sync_all_active_stocks(db, symbols)
        print(f"Total processed: {result['total']}")
        print(f"Successfully synced: {result['synced_count']}")
        if result["failed_count"]:
            print(f"Failed to sync: {result['failed_count']}")
        print("Real-time market sync completed.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
