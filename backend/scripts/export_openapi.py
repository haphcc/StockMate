"""Owner: TV4 - LB. Export/check the actual app's OpenAPI without a DB connection."""

import argparse
import json
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_DIR))

from app.main import app  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    path = BACKEND_DIR / "openapi.json"
    snapshot = json.dumps(app.openapi(), ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.check:
        if not path.exists() or path.read_text(encoding="utf-8") != snapshot:
            print("OpenAPI snapshot is stale. Run python scripts/export_openapi.py")
            return 1
        print("OpenAPI snapshot matches app.")
        return 0
    path.write_text(snapshot, encoding="utf-8")
    print("Exported backend/openapi.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
