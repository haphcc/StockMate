"""Check local docs/ownership; --write-owners refreshes the complete file inventory."""
import argparse
import fnmatch
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "docs/FILE_OWNERS.json"


def files() -> list[str]:
    output = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT,
    ).decode("utf-8")
    return sorted({p for p in output.split("\0") if p and (ROOT / p).is_file()})


def owner_of(path: str, registry: dict) -> str | None:
    for rule in registry["rules"]:
        if fnmatch.fnmatchcase(path, rule["pattern"]):
            return rule["owner"]
    return None


def inventory(paths: list[str], registry: dict) -> str:
    lines = [
        "# Ai phụ trách từng file", "",
        "Nguồn máy đọc: FILE_OWNERS.json; quy tắc khớp đầu tiên có hiệu lực.",
        "Một file có một chủ chính; người khác vẫn có thể đề xuất sửa bằng PR phối hợp.",
        "Chủ file chịu trách nhiệm tích hợp/review, không phải cơ chế khóa file của GitHub.", "",
        "Không có GitHub username của nhóm nên chưa tạo CODEOWNERS giả.",
        "Phuoc thêm username thật sau và cấu hình branch protection nếu nhóm dùng GitHub.", "",
        "## File chung cần phối hợp", "",
        "| File/nhóm | Chủ chính | Ai cần cùng kiểm tra |",
        "|---|---|---|",
        "| Schema/OpenAPI/examples | LB; trading schema: Tuệ | Sơn, Me, Châu |",
        "| Migration/SQL | Phuoc | Tuệ (luật), LB (mapping), Châu (regression) |",
        "| Router/providers/network/shared models | Sơn | Me đề xuất thay đổi qua cùng PR |",
        "| MarketRepository hiện có | Sơn | Me dùng để đọc thị trường; phối hợp nếu thêm method |",
        "| Pubspec/lock/theme/assets | Sơn | Me dùng lại, không tự tạo bộ theme thứ hai |",
        "| Tests integration/E2E | Châu | Người viết tính năng cung cấp fixture và điều kiện test |", "",
        "## Tra cứu nhanh", "",
        "`python scripts/check_preparation.py --owner TV2` để in file của Sơn.",
        "Sau khi tạo file: `python scripts/check_preparation.py --write-owners`.",
        "Dòng 'TODO' trong source là file khung, chưa có tính năng.", "",
    ]
    for key, person in registry["people"].items():
        lines.extend([f"## {key} — {person}", "", "| File |", "|---|"])
        for path in paths:
            if owner_of(path, registry) == key:
                # These links work from docs/, including nested paths and spaces.
                lines.append(f"| [{path}](../{path.replace(' ', '%20')}) |")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--owner", choices=[f"TV{i}" for i in range(1, 7)])
    parser.add_argument("--write-owners", action="store_true")
    args = parser.parse_args()
    registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    paths = files()
    errors = []
    for path in paths:
        owner = owner_of(path, registry)
        if owner is None:
            errors.append(f"Missing owner: {path}")
        elif owner not in registry["people"]:
            errors.append(f"Unknown owner {owner}: {path}")
        if args.owner == owner:
            print(path)
    if args.write_owners:
        target = ROOT / "docs/FILE_OWNERS.md"
        if "docs/FILE_OWNERS.md" not in paths:
            paths.append("docs/FILE_OWNERS.md")
        target.write_text(inventory(sorted(paths), registry), encoding="utf-8")
    for path in paths:
        if not path.endswith(".md"):
            continue
        source = (ROOT / path).read_text(encoding="utf-8")
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", source):
            parsed = urlparse(target)
            if parsed.scheme or target.startswith("#"):
                continue
            destination = (ROOT / path).parent / unquote(parsed.path)
            if not destination.exists():
                errors.append(f"Broken link: {path} -> {target}")
    if errors:
        raise SystemExit("\n".join(errors))
    if not args.owner:
        print(f"Preparation OK: {len(paths)} files have owners; Markdown links resolve")


if __name__ == "__main__":
    main()
