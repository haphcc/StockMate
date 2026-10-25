# Hợp đồng API v1

Chủ: TV4 — LB; phần orders/transactions/notifications: TV5 — Tuệ.
Schema chuẩn: `backend/app/schemas/`; snapshot máy đọc: [openapi.json](../backend/openapi.json).
Swagger chạy tại http://localhost:8000/docs. Khung hiện trả 501 cho endpoint nghiệp vụ.

## Quy ước dùng chung

- Prefix `/api` (không thêm `/v1` vào URL vì mobile hiện dùng `/api`).
- JSON snake_case; `Content-Type: application/json`; xác thực `Authorization: Bearer <access_token>`.
- Tiền/giá/giá vốn/phí/thuế là **string thập phân VND**, luôn 2 chữ số lẻ, ví dụ `"62800.00"`.
- Phần trăm cũng string 2 số lẻ; `profit_loss_percent=null` khi mẫu số 0.
- ID, quantity, volume, count là JSON integer. Không parse tiền qua double rồi làm tròn lại.
- Flutter dùng Decimal hoặc số nguyên đơn vị 0.01 đồng; chia 1000 chỉ ở bước hiển thị giá.
- Datetime ISO 8601 có timezone, server trả UTC; `settlement_date`, OHLCV date là `YYYY-MM-DD`.
- `StockResponse` là cấu trúc giá; `PortfolioResponse` **phẳng**, không có object `stock`.
- `WatchlistResponse` có `stock` lồng theo schema; đây là lựa chọn riêng cho watchlist.
- Page envelope: `{"items":[],"page":1,"page_size":20,"total":0}`; page≥1, page_size 1–100.
- Các danh sách nhỏ (accounts, portfolio, chart, watchlist) là array thuần theo OpenAPI.
- Sort cố định: board theo total_volume DESC rồi stock_symbol ASC; orders/transactions/notifications
  theo timestamp DESC rồi ID DESC; chart theo date ASC; accounts/portfolio/watchlist theo ID ASC.

## Endpoint và người thực hiện

Tất cả ngoài register/login/refresh và health cần JWT. MVP không có endpoint ghi trực tiếp transaction.

| Method + đường dẫn | Input/response | Chủ |
|---|---|---|
| GET `/health/live` | 200 process sống | LB |
| GET `/health/ready` | 200 kết nối DB; 503 lỗi DB. Không khẳng định engine đã sẵn sàng | LB |
| POST `/api/auth/register` | RegisterRequest → TokenResponse, 201 | LB |
| POST `/api/auth/login` | LoginRequest → TokenResponse, 200 | LB |
| POST `/api/auth/refresh` | RefreshRequest → TokenResponse, 200 | LB |
| GET `/api/auth/me` | UserResponse | LB |
| GET `/api/accounts` | AccountResponse[] chỉ tài khoản của khách hiện tại | LB |
| GET `/api/accounts/{account_id}/assets` | AssetResponse | LB |
| GET `/api/accounts/{account_id}/portfolio` | PortfolioResponse[] | LB |
| GET `/api/market/board` | exchange?, q?, page, page_size → Page[StockResponse] | LB |
| GET `/api/stocks/{symbol}` | StockResponse | LB |
| GET `/api/stocks/{symbol}/chart` | range=1M/3M/6M → CandleResponse[] | LB |
| GET `/api/watchlist` | WatchlistResponse[] | LB |
| POST `/api/watchlist` | {stock_symbol} → WatchlistResponse, 201; thêm lại trả cùng bản ghi | LB |
| DELETE `/api/watchlist/{symbol}` | 204 không body; xóa mã chưa có vẫn 204 | LB |
| GET `/api/accounts/{account_id}/orders` | status?, page, page_size → Page[OrderResponse] | Tuệ |
| POST `/api/accounts/{account_id}/orders` | CreateOrderRequest → OrderResponse, 201 | Tuệ |
| DELETE `/api/orders/{order_id}` | Hủy → OrderResponse, 200 | Tuệ |
| GET `/api/accounts/{account_id}/transactions` | page, page_size → Page[TransactionResponse] | Tuệ |
| GET `/api/notifications` | unread=false/true, page, page_size → Page[NotificationResponse] | Tuệ |
| POST `/api/notifications/{notification_id}/read` | NotificationResponse; gọi lại vẫn 200 | Tuệ |

`q` tìm không phân biệt hoa/thường theo mã hoặc tên. MVP không bỏ dấu tiếng Việt.
Chart 1M/3M/6M = tối đa 22/66/132 phiên gần nhất, trả tăng dần theo ngày.
Seed cũ chưa có client_order_id: migration 0002 phải backfill UUID cho lệnh lịch sử.

## Request mẫu

```json
{
  "full_name": "Nguyen Van Demo",
  "email": "demo@example.com",
  "phone_number": "0909999999",
  "password": "Matkhau@123"
}
```

```json
{
  "client_order_id": "12345678-1234-4234-8234-123456789abc",
  "stock_symbol": "FPT",
  "order_type": "BUY",
  "order_kind": "LO",
  "quantity": 100,
  "order_price": "100000.00"
}
```

Response mẫu đầy đủ cho FE nằm ở [contracts/examples.json](contracts/examples.json).
Đây là fixture, không phải phản hồi thật từ API đang hoạt động.

## Lỗi

```json
{"error":{"code":"INSUFFICIENT_CASH","message":"Không đủ sức mua.","details":{}}}
```

| HTTP | Code | Client xử lý |
|---|---|---|
| 401 | UNAUTHORIZED / INVALID_CREDENTIALS / TOKEN_EXPIRED | Chỉ refresh với TOKEN_EXPIRED hoặc access hết hạn; refresh một lần |
| 403 | ACCOUNT_INACTIVE / UNSUPPORTED_ACCOUNT_TYPE | Báo lý do, không retry |
| 404 | NOT_FOUND | Không tiết lộ tài nguyên của người khác |
| 409 | DUPLICATE_EMAIL / DUPLICATE_PHONE / INSUFFICIENT_CASH / INSUFFICIENT_SHARES / IDEMPOTENCY_CONFLICT / ORDER_NOT_CANCELLABLE / STALE_QUOTE | Hiển thị thông báo, refresh dữ liệu nếu cần |
| 422 | VALIDATION_ERROR / INVALID_PRICE_TICK / PRICE_OUT_OF_BAND / UNSUPPORTED_ORDER_KIND | Báo ở form |
| 501 | NOT_IMPLEMENTED | Chức năng chưa triển khai, không hiện thành công |
| 503 | DATABASE_UNAVAILABLE / MARKET_UNAVAILABLE | Cho thử lại; không tạo UUID mới khi retry cùng lệnh |

MVP server chưa có blacklist token; không thêm route logout giả. Refresh thất bại → clear session và về login.

## Thay đổi contract đúng cách

1. Sửa schema/route cùng response mapping; không chỉ sửa snapshot JSON.
2. Cập nhật examples và test của payload bị ảnh hưởng.
3. Trong `backend/`: `python -m scripts.export_openapi`.
4. Chạy `python -m pytest` và `python -m scripts.export_openapi --check`.
5. PR có LB + chủ phần Flutter liên quan review; Châu chạy lại test case tích hợp.
