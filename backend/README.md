# StockMate — Backend (FastAPI + PostgreSQL)

Khung thư mục cho API của app giao dịch chứng khoán.
Hiện mới có cấu trúc thư mục và file cấu hình; phần code sẽ viết sau.

## 1. Chuẩn bị môi trường

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS / Linux

pip install -r requirements.txt
copy .env.example .env          # Windows  (cp .env.example .env trên macOS/Linux)
```

Nạp database (xem `../data/README.md`):

```bash
psql -h localhost -U postgres -d stock_exchange -f ../data/postgres/00_run_all.sql
```

Chạy server (sau khi đã có `app/main.py`):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Tài liệu API tự sinh: http://localhost:8000/docs

> Dùng `--host 0.0.0.0` để Android emulator gọi được qua `http://10.0.2.2:8000`.

## 2. Cấu trúc thư mục

```
backend/
├── alembic/
│   └── versions/          # file migration sinh bằng: alembic revision --autogenerate
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/ # 1 file/nhóm route: auth, market, accounts, orders,
│   │       │              # transactions, watchlist, notifications
│   │       └──            # api.py: gom các router của v1
│   ├── core/              # config (đọc .env), security (JWT, hash mật khẩu), exception handler
│   ├── crud/              # truy vấn DB thuần theo từng bảng
│   ├── db/                # engine, SessionLocal, Base, dependency get_db()
│   ├── models/            # SQLAlchemy ORM, map với 9 bảng trong data/postgres
│   ├── schemas/           # Pydantic: request/response của API
│   ├── services/          # nghiệp vụ: kiểm tra sức mua, biên độ giá, đặt/huỷ lệnh
│   ├── utils/             # tiện ích chung
│   └──                    # main.py: khởi tạo FastAPI app, CORS, đăng ký router
├── scripts/               # script vận hành: seed, cập nhật giá, job đầu phiên
├── tests/
│   ├── integration/
│   └── unit/
├── .env.example
└── requirements.txt
```

Mỗi thư mục có `.gitkeep`; xoá khi đã có code thật. Nhớ thêm `__init__.py`
vào các thư mục trong `app/` khi bắt đầu code để Python nhận là package.

## 3. Phân chia việc theo nhóm endpoint

Các đường dẫn dưới đây đã được thống nhất sẵn với frontend
(`mobile/lib/core/network/api_endpoints.dart` sẽ dùng đúng danh sách này)
và bám theo các view trong `../data/postgres/08_views.sql`.

| Nhóm | Endpoint | View / bảng dùng |
|---|---|---|
| Auth | `POST /api/auth/login`, `/register`, `/refresh`, `GET /api/auth/me` | `customers` |
| Bảng giá | `GET /api/market/board?exchange=HOSE` | `v_market_board` |
| Chi tiết mã | `GET /api/stocks/{symbol}`, `GET /api/stocks/{symbol}/chart` | `stocks`, `stock_price_history` |
| Tài khoản | `GET /api/accounts`, `/{id}/assets` | `v_account_summary` |
| Danh mục | `GET /api/accounts/{id}/portfolio` | `v_portfolio_detail` |
| Lệnh | `GET/POST /api/accounts/{id}/orders`, `DELETE /api/orders/{id}` | `v_order_book`, `stock_orders` |
| Lịch sử GD | `GET /api/accounts/{id}/transactions` | `v_transaction_history` |
| Quan tâm | `GET/POST/DELETE /api/watchlist` | `v_watchlist_detail` |
| Thông báo | `GET /api/notifications`, `POST /api/notifications/{id}/read` | `notifications` |

## 4. Lưu ý khi code

- **Nghiệp vụ khớp lệnh đã nằm trong database**: chỉ cần `INSERT` vào `transactions`,
  trigger sẽ tự cập nhật danh mục, giá vốn bình quân, số dư tiền và trạng thái lệnh.
  Đừng tính lại ở tầng Python để tránh lệch số liệu.
- Tiền và giá dùng `NUMERIC` → map sang `Decimal` trong Python, **không dùng `float`**.
- Mật khẩu hash bằng `passlib` (bcrypt). Hash trong dữ liệu mẫu là chuỗi mẫu,
  phải sinh lại trước khi bật đăng nhập (xem `../data/README.md`).
- `.env` chứa `SECRET_KEY` và mật khẩu DB — đã bị `.gitignore` chặn, đừng commit.
- Nếu `passlib` báo lỗi khi đọc version của `bcrypt`, pin `bcrypt<5` trong requirements.
