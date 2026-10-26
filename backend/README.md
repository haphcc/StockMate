# StockMate — Backend

Checkpoint 1 của TV4 đã có API thực thi: health, đăng ký, đăng nhập, refresh JWT,
thông tin người dùng và danh sách tài khoản. Các API thị trường/tài sản/watchlist và nghiệp vụ
giao dịch còn thuộc các chặng sau. Backend Admin của Phuoc được giữ và kiểm tra hồi quy.

## Chuẩn bị

Từ thư mục backend trên PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.lock.txt
```

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

Sửa `DATABASE_URL` trong `.env` cho đúng PostgreSQL DEV của bạn. Tạo database trống trước.
Thay `SECRET_KEY` bằng khóa tự sinh và giữ riêng `.env`. Không commit khóa/token.
JWT mặc định: access 15 phút, refresh 14 ngày. Nếu PowerShell đã có biến `DATABASE_URL`,
biến môi trường đó được ưu tiên hơn `.env`.

Nếu chạy PostgreSQL bằng Compose, biến `POSTGRES_PASSWORD` của Compose phải khớp
`DATABASE_URL` trong `backend/.env`; Compose không tự đọc `backend/.env`.

## Dựng database và chạy API

Từ `backend/`, với PostgreSQL đang chạy:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe scripts/seed_demo.py
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Seed là tùy chọn cho đăng ký mới. Seed demo cung cấp 90 stocks, 10 customers, 13 accounts;
đăng nhập bằng `an.nguyen@gmail.com` (ADMIN) hoặc `bich.tran@gmail.com` (CUSTOMER),
mật khẩu demo `Matkhau@123`. Seed từ chối ghi lại khi đã có khách hàng.
Không chạy SQL reset prototype lên database cần giữ dữ liệu.

Swagger: http://localhost:8000/docs; OpenAPI: http://localhost:8000/api/openapi.json.
Android emulator gọi `http://10.0.2.2:8000`; máy thật dùng IP LAN của máy backend.

## Bàn giao checkpoint 1

| Method | URL | Kết quả |
|---|---|---|
| GET | `/health/live` | 200 process sống |
| GET | `/health/ready` | 200 DB kết nối; 503 nếu lỗi DB |
| POST | `/api/auth/register` | 201 user + CASH account + 1 tỷ tiền giả lập, access/refresh JWT |
| POST | `/api/auth/login` | 200 cặp JWT và user |
| POST | `/api/auth/refresh` | 200 cặp JWT và user, body `{refresh_token}` |
| GET | `/api/auth/me` | User của access JWT |
| GET | `/api/accounts` | Array tài khoản của chính user, sort account_id ASC |

Register nhận đủ `full_name`, `email`, `phone_number`, `password` theo
[API_CONTRACT](../docs/API_CONTRACT.md). Các route `me/accounts` dùng
`Authorization: Bearer <access_token>`; refresh token không được dùng thay access.
Mọi lỗi dùng `{ "error": { "code": "...", "message": "...", "details": {} } }`.

`AccountResponse` có `account_id`, `account_number`, `account_type`, `status`, theo contract.
API tài sản trả tiền string là việc chặng 2; `/api/accounts` không trả số dư.
App Flutter vẫn dùng mock; Sơn cần nối datasource/token flow và cập nhật model theo contract.
Chưa coi chặng 1 toàn nhóm hoàn tất trước khi Sơn/Châu thử trên app.

## Kiểm tra

```powershell
.\.venv\Scripts\python.exe -m pytest tests/unit/test_auth_checkpoint.py -q
.\.venv\Scripts\python.exe -m ruff check app scripts tests alembic
.\.venv\Scripts\python.exe -m ruff format --check app scripts tests alembic
.\.venv\Scripts\python.exe scripts/export_openapi.py --check
```

Integration CP1 dùng PostgreSQL thật. Đặt `TEST_DATABASE_URL` tới server DEV với user có quyền
`CREATEDB` (ví dụ URL `postgresql+psycopg://postgres:<password>@localhost:5432/postgres`), rồi chạy:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/integration/test_auth_checkpoint_postgres.py -q
```

Suite tự tạo/xóa database ngẫu nhiên `stockmate_cp1_test_*`, không ghi lên database trong URL gốc.
Nếu thiếu biến, integration CP1 sẽ SKIP; không coi SKIP là đã kiểm thử DB.
Để chạy toàn bộ `pytest`, `DATABASE_URL` còn phải trỏ tới DB DEV đã migrate/seed riêng cho
bộ test Admin hiện có (bộ này thay đổi dữ liệu demo).
Khi đổi API: chạy `python scripts/export_openapi.py` để cập nhật `backend/openapi.json`.

Kết quả và giới hạn kiểm thử: [TV4_CP1](../docs/qa/TV4_CP1.md).

Tra [START_HERE](../docs/START_HERE.md), [SETUP](../docs/SETUP.md),
[API_CONTRACT](../docs/API_CONTRACT.md), [DATABASE_WORKFLOW](../docs/DATABASE_WORKFLOW.md),
[TV4 — LB](../docs/team/TV4_LB.md), [TV5 — Tuệ](../docs/team/TV5_TUE.md).
