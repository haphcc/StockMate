"""Owner: TV4 - LB. Export/check the actual app's OpenAPI without a DB connection."""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

BACKEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_DIR))

from app.main import app  # noqa: E402

DECIMAL_REGEX = r"^(?!^[-+.]*$)[+-]?0*\d*\.?\d*$"


def normalize_schema(obj: Any) -> Any:
    """Normalize differences across pydantic versions (e.g. Decimal pattern insertion)."""
    if isinstance(obj, dict):
        return {
            k: normalize_schema(v)
            for k, v in obj.items()
            if not (k == "pattern" and v == DECIMAL_REGEX)
        }
    elif isinstance(obj, list):
        return [normalize_schema(item) for item in obj]
    return obj


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    path = BACKEND_DIR / "openapi.json"

    schema = normalize_schema(app.openapi())
    snapshot = json.dumps(schema, ensure_ascii=False, indent=2, sort_keys=True) + "\n"

    if args.check:
        current_content = path.read_text(encoding="utf-8") if path.exists() else ""
        current_schema = normalize_schema(json.loads(current_content)) if current_content else {}
        current_normalized = (
            json.dumps(current_schema, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        )
        if not path.exists() or current_normalized != snapshot:
            print("OpenAPI snapshot is stale. Run python scripts/export_openapi.py")
            return 1
        print("OpenAPI snapshot matches app.")
        return 0

    path.write_text(snapshot, encoding="utf-8")
    print("Exported backend/openapi.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
