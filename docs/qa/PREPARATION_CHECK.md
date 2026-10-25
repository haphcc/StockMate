# Kiểm tra bộ chuẩn bị — 25/10/2026

Phạm vi: khung dự án và hướng dẫn, chưa phải nghiệm thu tính năng MVP.

| Hạng mục | Trạng thái |
|---|---|
| Python local | 3.14.7; nhóm/Docker/CI dùng Python 3.13 |
| Dependency backend | Cài trong backend/.venv, khóa phiên bản; pip check không có dependency lỗi |
| Unit/HTTP/fixture tests | PASS: 36 passed; 3 DB integration tests skipped do chưa có TEST_DATABASE_URL |
| Migration/seed integration | NOT RUN local: Docker Linux engine chưa kết nối được, không có PostgreSQL local |
| Compose | PASS `docker compose config --quiet`; chưa chạy container/migrate/seed thực tế |
| Flutter analyze/test/APK | NOT RUN: Flutter không có trong PATH phiên chuẩn bị |
| Luồng register/login/market/trading thật | TODO theo WORK_BOARD; nghiệp vụ hiện trả 501 |
| Ownership + Markdown links | PASS: 323 file có chủ; liên kết nội bộ tồn tại |
| OpenAPI snapshot | PASS: khớp schema/route hiện tại |
| Ruff + format | PASS; 68 file Python đúng quy ước formatter |
| Alembic history | PASS: nhận revision 0001 head; chưa áp dụng lên PostgreSQL local |

Pytest có một cảnh báo deprecation từ Starlette TestClient/httpx ở dependency mới;
không có test failure. CI Python 3.13/Linux và Flutter vẫn cần chạy trên môi trường nhóm/remote.

## Điểm đã xác nhận từ source/test nền

- Liveness chạy không cần DB; lỗi DB readiness trả 503 theo envelope.
- Thiếu bearer trả 401; token tùy ý không được coi là xác thực thành công.
- Endpoint login khung trả 501, không tạo token giả.
- Schema money giữ phần lẻ, số lớn; từ chối float/NaN/Infinity và lot không hợp lệ.
- Fixture các nhóm API có test đối chiếu schema.
- Migration baseline bỏ DROP, từ chối DB đã có bảng app; seed không reset DB và từ chối dữ liệu có sẵn.
  Hai đặc tính DB này vẫn phải chạy integration thực tế trước khi ENV-01 sang DONE.

## Lệnh chạy lại

Từ backend: `python -m ruff check app scripts tests alembic`,
`python -m ruff format --check app scripts tests alembic`, `python -m pytest -q`,
`python -m scripts.export_openapi --check`, `python -m pip check`.
Từ repo gốc: `python scripts/check_preparation.py`, `docker compose config --quiet`.
Xem SETUP cho lệnh Python .venv trên PowerShell.

CI đã khai báo PostgreSQL thật để kiểm tra bootstrap khi chạy workflow; chưa có kết quả CI remote trong phiên này.
