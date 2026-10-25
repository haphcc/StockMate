import argparse
import json
from pathlib import Path

from app.main import app

TARGET = Path(__file__).resolve().parents[1] / "openapi.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = json.dumps(app.openapi(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not TARGET.exists() or TARGET.read_text(encoding="utf-8") != rendered:
            raise SystemExit("OpenAPI changed. Run python -m scripts.export_openapi")
        print("OpenAPI snapshot is current")
    else:
        TARGET.write_text(rendered, encoding="utf-8")
        print(TARGET)


if __name__ == "__main__":
    main()
