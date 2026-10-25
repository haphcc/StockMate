# Kiểm tra bộ chuẩn bị — 25/10/2026

Phạm vi: khung dự án và hướng dẫn, chưa phải nghiệm thu tính năng MVP.

| Hạng mục | Trạng thái |
|---|---|
| Python local | 3.14.7; nhóm/Docker/CI dùng Python 3.13 |
| Dependency backend | Cài trong backend/.venv, khóa phiên bản; pip check không có dependency lỗi |
| Unit/HTTP/fixture + DB tests | PASS CI: 39 passed, không skip; local: 36 passed, 3 DB tests skipped |
| Migration/seed integration | PASS CI PostgreSQL 16: migrate, seed, kiểm tra dữ liệu, từ chối seed lặp và migrate lặp; chưa chạy PostgreSQL local |
| Compose | PASS `docker compose config --quiet`; chưa chạy container/migrate/seed thực tế |
| Flutter analyze/test | PASS CI Flutter 3.47.5: analyze không có issue, 1 widget test passed; Flutter chưa có trong PATH local |
| Flutter APK | NOT RUN: workflow hiện chưa build APK |
| Luồng register/login/market/trading thật | TODO theo WORK_BOARD; nghiệp vụ hiện trả 501 |
| Ownership + Markdown links | PASS: 323 file có chủ; liên kết nội bộ tồn tại |
| OpenAPI snapshot | PASS: khớp schema/route hiện tại |
| Ruff + format | PASS; 68 file Python đúng quy ước formatter |
| Alembic history | PASS: revision 0001 head; đã áp dụng lên PostgreSQL 16 trong CI |

Pytest có một cảnh báo deprecation từ Starlette TestClient/httpx ở dependency mới;
không có test failure. CI Python 3.13/Linux và Flutter đã PASS tại commit `99bea65`:
[GitHub Actions run 40209906134](https://github.com/haphcc/StockMate/actions/runs/40209906134).

## Điểm đã xác nhận từ source/test nền

- Liveness chạy không cần DB; lỗi DB readiness trả 503 theo envelope.
- Thiếu bearer trả 401; token tùy ý không được coi là xác thực thành công.
- Endpoint login khung trả 501, không tạo token giả.
- Schema money giữ phần lẻ, số lớn; từ chối float/NaN/Infinity và lot không hợp lệ.
- Fixture các nhóm API có test đối chiếu schema.
- Migration baseline bỏ DROP, từ chối DB đã có bảng app; seed không reset DB và từ chối dữ liệu có sẵn.
  CI đã xác nhận seed từ chối dữ liệu sẵn có và migrate lặp không thay đổi schema.

## Lệnh chạy lại

Từ backend: `python -m ruff check app scripts tests alembic`,
`python -m ruff format --check app scripts tests alembic`, `python -m pytest -q`,
`python -m scripts.export_openapi --check`, `python -m pip check`.
Từ repo gốc: `python scripts/check_preparation.py`, `docker compose config --quiet`.
Xem SETUP cho lệnh Python .venv trên PowerShell.

Workflow nằm ở `.github/workflows/checks.yml`, chạy khi push lên `main` hoặc mở/cập nhật pull request.
Lỗi CI ban đầu đã sửa: thực thi script SQL không truyền tham số để giữ nguyên `%`,
và bổ sung `const` tại các widget Flutter được analyzer chỉ ra. Cả hai job backend/mobile đã PASS.
