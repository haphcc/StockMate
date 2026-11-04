# StockMate — Backend

Phần backend demo của TV4 đã có API auth/accounts, bảng giá, chi tiết/chart, watchlist,
tài sản và danh mục. Đã tích hợp API giao dịch của Tuệ để kiểm tra tài sản sau mua/bán/hủy/T+2.
Đã hỗ trợ tích hợp dữ liệu chứng khoán theo thời gian thực (SSI iBoard & DNSE) và đồng bộ DB.
Backend Admin của Phuoc được giữ và kiểm tra hồi quy. Flutter/APK vẫn do chủ phần bàn giao.

## Chuẩn bị

Khởi tạo môi trường ảo Python 3.13 và cài đặt dependency đã khóa:

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
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

## Khởi tạo và kiểm tra bước 1 (LB CP1)

Đăng ký user mới tự động tạo tài khoản CASH và nạp 1.000.000.000 VNĐ giả lập:

```powershell
$reg = Invoke-RestMethod -Method Post -Uri http://localhost:8000/api/auth/register `
  -ContentType 'application/json' `
  -Body '{"full_name":"Test User","email":"test@example.com","phone_number":"0901234567","password":"Password@123"}'
$access = $reg.access_token

Invoke-RestMethod -Uri http://localhost:8000/api/accounts `
  -Headers @{ Authorization = "Bearer $access" }
```

JSON lỗi chuẩn:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Chi tiết lỗi",
    "details": {}
  }
}
```

## API bước 2 (LB CP2)

Tất cả endpoint dưới đây cần access JWT. JSON ví dụ nằm trong
`docs/contracts/examples.json`; schema thực thi trong OpenAPI.

| Method | URL | Kết quả |
|---|---|---|
| GET | `/api/market/board?exchange=HOSE&q=FPT&page=1&page_size=20` | Page cổ phiếu, sort volume DESC/symbol ASC (`?live=true` để lấy giá trực tiếp) |
| GET | `/api/stocks/FPT` | Giá, thay đổi/phần trăm, price_state (`?live=true` để lấy giá thời gian thực từ sàn) |
| GET | `/api/stocks/FPT/chart?range=1M` | Tối đa 22 nến mới nhất, ngày ASC; 3M/6M là 66/132 phiên (`?live=true` nến thực tế) |
| POST | `/api/market/sync-live` | Đồng bộ giá thời gian thực từ sàn chứng khoán vào database (`{"symbols": ["SSI", "VNM"]}`) |
| GET | `/api/watchlist` | Array watchlist với object stock lồng |
| POST | `/api/watchlist` | Body `{ "stock_symbol": "FPT" }`; 201; thêm lại giữ cùng ID |
| DELETE | `/api/watchlist/FPT` | 204 không body; xóa lại vẫn 204 |
| GET | `/api/accounts/{account_id}/assets` | Cash/blocked/stock_value/NAV/lãi lỗ tính từ giá DB hiện tại |
| GET | `/api/accounts/{account_id}/portfolio` | Array danh mục phẳng, available/blocked/pending và giá vốn |

Tiền/giá/phần trăm là string 2 số lẻ, Decimal HALF_UP. Phần trăm lãi lỗ null khi giá vốn 0;
change_percent null khi giá tham chiếu 0. NAV = cash + blocked + tổng quantity × market_price.
Các cột NAV/current_value đã lưu không được dùng thay cho định giá hiện tại khi đọc API.
Tài khoản người khác và tài khoản không tồn tại đều trả 404 như nhau.

Mã/sàn đang HALTED/DELISTED vẫn có thể xem để đọc lịch sử; API đặt lệnh của Tuệ kiểm tra
trạng thái giao dịch. Khi không truyền `?live=true`, giá mặc định lấy từ DB với `data_source="DEMO"`,
`is_stale=true`. Khi truyền `?live=true`, hệ thống lấy dữ liệu trực tiếp từ sàn qua SSI iBoard / DNSE
với `data_source="LIVE"`, `is_stale=false` và tự động cập nhật giá vào DB.

### Đồng bộ dữ liệu chứng khoán thời gian thực qua CLI

Có thể đồng bộ dữ liệu thời gian thực từ sàn vào PostgreSQL qua script:

```powershell
# Đồng bộ danh sách mã cụ thể:
.\.venv\Scripts\python.exe scripts/sync_realtime_quotes.py --symbols SSI,VNM,HPG,FPT,TCB

# Hoặc đồng bộ tất cả mã ACTIVE trong database:
.\.venv\Scripts\python.exe scripts/sync_realtime_quotes.py
```

## Kiểm tra

```powershell
.\.venv\Scripts\python.exe -m pytest tests/unit -q
.\.venv\Scripts\python.exe -m ruff check app scripts tests alembic
.\.venv\Scripts\python.exe -m ruff format --check app scripts tests alembic
.\.venv\Scripts\python.exe scripts/export_openapi.py --check
```

Integration của LB dùng PostgreSQL thật. Đặt `TEST_DATABASE_URL` tới server DEV với user có quyền
`CREATEDB` (ví dụ URL `postgresql+psycopg://postgres:<password>@localhost:5432/postgres`), rồi chạy:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/integration -q
```

Suite tự tạo/xóa database ngẫu nhiên `stockmate_cp1_test_*`/`stockmate_lb_test_*`,
chạy migration Alembic, nạp seed và dọn dẹp sau khi chạy.
