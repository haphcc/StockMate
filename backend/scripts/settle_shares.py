"""Owner: TV5 - Tuệ.

CLI maintenance job to settle T+2 pending shares.
Supports optional --as-of-date parameter for deterministic testing.
"""

import argparse
import sys
from datetime import datetime
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.db.session import SessionLocal
from app.services.settlement_service import process_share_settlements


def main() -> None:
    parser = argparse.ArgumentParser(description="StockMate T+2 Share Settlement Job")
    parser.add_argument(
        "--as-of-date",
        type=str,
        default=None,
        help="Target date for settlement in YYYY-MM-DD format (defaults to current date in Vietnam)",
    )
    args = parser.parse_args()

    as_of_date = None
    if args.as_of_date:
        try:
            as_of_date = datetime.strptime(args.as_of_date, "%Y-%m-%d").date()
        except ValueError:
            print(f"Error: Invalid date format '{args.as_of_date}'. Expected YYYY-MM-DD.")
            sys.exit(1)

    print(f"Running T+2 share settlement (as_of_date: {as_of_date or 'Today'})...")

    db = SessionLocal()
    try:
        settled = process_share_settlements(db, as_of_date=as_of_date)
        print(f"Successfully processed {len(settled)} settlement batch(es).")
        for item in settled:
            symbol = item.stock.stock_symbol if item.stock else f"Stock {item.stock_id}"
            print(
                f"  - Account {item.account_id}: +{item.quantity} shares of {symbol} "
                f"(Tx: {item.transaction_id}, Due: {item.settlement_date})"
            )
    except Exception as e:
        print(f"Settlement failed with error: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
