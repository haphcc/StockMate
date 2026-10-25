# StockMate — Backend (FastAPI + PostgreSQL)

Khung FastAPI đã chạy được health checks, config, lỗi thống nhất và OpenAPI.
Endpoint nghiệp vụ có schema nhưng trả `501 NOT_IMPLEMENTED` cho đến khi chủ task triển khai.

Đọc trước: [START_HERE](../docs/START_HERE.md), [SETUP](../docs/SETUP.md),
[API_CONTRACT](../docs/API_CONTRACT.md), [DATABASE_WORKFLOW](../docs/DATABASE_WORKFLOW.md).
LB làm theo [TV4](../docs/team/TV4_LB.md), Tuệ theo [TV5](../docs/team/TV5_TUE.md).

## 1. Chuẩn bị môi trường

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS / Linux

pip install -r requirements.lock.txt
copy .env.example .env          # Windows  (cp .env.example .env trên macOS/Linux)
```

Database phải trống, PostgreSQL 16 đang chạy (xem SETUP; không reset DB cũ):

```bash
python -m alembic upgrade head
python -m scripts.seed_demo
```

Chạy server:

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

Các module có docstring TODO(task-id) là file bàn giao, chưa có implementation.
Phân quyền file: [FILE_OWNERS](../docs/FILE_OWNERS.md). Không tính số file TODO là tiến độ feature.

## 3. Phân chia việc theo nhóm endpoint

Danh sách dưới đây là tóm tắt; source chuẩn là app/schemas, openapi.json và API_CONTRACT.
`mobile/lib/core/network/api_endpoints.dart` đã có hằng số URL tương ứng.

| Nhóm | Endpoint | View / bảng dùng |
|---|---|---|
| Auth | `POST /api/auth/login`, `/register`, `/refresh`, `GET /api/auth/me` | `customers` |
| Bảng giá | `GET /api/market/board?exchange=HOSE` | `v_market_board` |
| Chi tiết mã | `GET /api/stocks/{symbol}`, `GET /api/stocks/{symbol}/chart` | `stocks`, `stock_price_history` |
| Tài khoản | `GET /api/accounts`, `/{id}/assets` | `v_account_summary` |
| Danh mục | `GET /api/accounts/{id}/portfolio` | `v_portfolio_detail` |
| Lệnh | `GET/POST /api/accounts/{id}/orders`, `DELETE /api/orders/{id}` | `v_order_book`, `stock_orders` |
| Lịch sử GD | `GET /api/accounts/{id}/transactions` | `v_transaction_history` |
| Quan tâm | `GET/POST /api/watchlist`, `DELETE /api/watchlist/{symbol}` | `v_watchlist_detail` |
| Thông báo | `GET /api/notifications`, `POST /api/notifications/{id}/read` | `notifications` |

## 4. Lưu ý khi code

- Backend xác thực/ownership, validation sau khóa, điều phối một transaction; SQL routine tính và
  apply số dư/giao dịch. Trigger baseline chưa xử lý đủ reserve/cancel/settlement: làm TR-01/02/03.
- Tiền và giá dùng `NUMERIC` → map sang `Decimal` trong Python, **không dùng `float`**.
- scripts.seed_demo tạo hash bcrypt thật cho mật khẩu demo; endpoint auth vẫn cần BE-01.
- `.env` chứa `SECRET_KEY` và mật khẩu DB — đã bị `.gitignore` chặn, đừng commit.
- Dependency đã có lock; đổi dependency thì resolve lại và kiểm tra CI Python 3.13/Linux.

## 5. Kiểm tra nền

```bash
python -m ruff check app scripts tests alembic
python -m pytest -q
python -m scripts.export_openapi --check
```

Đổi contract: chạy `python -m scripts.export_openapi` rồi commit snapshot cùng schema.
Database integration cần TEST_DATABASE_URL tới DB dùng riêng tên kết thúc `_test`, đã migrate/seed.
