# TV4 — Checkpoint 2/3: thị trường, tài sản và bàn giao tích hợp

Ngày chạy: 04/11/2026 (Asia/Bangkok).
Nhánh: `traidep`; base tích hợp `aac860e` (ghép main `04d2edb` với CP1 `61599b7`)
cùng các thay đổi CP2/3. Commit CP2/3 và CI xem lịch sử nhánh GitHub.
Môi trường local: Windows, Python 3.14.7, PostgreSQL 16-alpine trong container test riêng,
loopback cổng 55434. Migration head: `0005_fix_trading_engine_trigger`.

## Kết quả

```text
python -m pytest -q --tb=short
114 passed, 9 warnings in 26.78s

python -m ruff check app scripts tests alembic
All checks passed!

python -m ruff format --check app scripts tests alembic
83 files already formatted

python scripts/export_openapi.py --check
OpenAPI snapshot matches app.
```

Compileall và `git diff --check`: PASS. Không skip/xfail trong lượt full suite.
Warnings là deprecation có sẵn của Starlette/httpx, Alembic path_separator và tên hằng HTTP 422.
Full suite giữ lại 79 test auth/Admin/trading đã có và thêm 35 test/case của LB.

`DATABASE_URL` trỏ tới DB test trống, đã migrate/seed mới cho toàn bộ suite. Đây là điều kiện
của bộ Admin/trading cũ dùng ID demo cố định và ghi dữ liệu trong khi chạy.
`TEST_DATABASE_URL` trỏ tới server PostgreSQL có quyền CREATEDB; integration của LB tự tạo
database ngẫu nhiên `stockmate_lb_test_*`, chỉ truncate/drop bên trong database đó.

## Phạm vi kiểm thử và nghiệm thu server

| Case | Thực hiện/expected | Actual | Kết quả |
|---|---|---|---|
| QA-MKT-01 | Filter HOSE/HNX/UPCOM, q theo mã/tên không phân biệt hoa thường, literal %/_, page/tie-sort | Đúng page envelope, total cả trang ngoài phạm vi; volume DESC/symbol ASC | PASS |
| QA-MKT-02 chart | 1M/3M/6M lấy 22/66/132 phiên gần nhất, trả date ASC | Kiểm tra với 140 bản ghi; chart trống và symbol thiếu được phân biệt | PASS |
| QA-MKT-02 watchlist | Thêm/xóa lặp, thêm đồng thời không trùng, không sửa của người khác | 201 cùng ID; DELETE lặp 204 không body; 6 POST đồng thời chỉ một bản ghi | PASS |
| Legacy watchlist | Seed nhiều tên danh sách/mã trùng | Merged theo mã, ID nhỏ nhất, sort ID ASC; delete xóa hết mục legacy của chính user | PASS |
| QA-MKT-03 phần server | 5 trạng thái giá, format Decimal và UTC | CEILING/FLOOR/REFERENCE/UP/DOWN đúng; nguồn DEMO, is_stale true | PASS |
| QA-MKT-04 phần server | Đổi giá cổ phiếu đang giữ rồi đọc lại | Quote/watchlist và NAV/danh mục dùng giá mới, không dùng giá trị tổng hợp cũ | PASS |
| QA-OWN-01 | User khác đọc assets/portfolio/orders/transactions, cancel/read notification | 404; không làm thay đổi tiền phong tỏa của chủ tài khoản | PASS |
| QA-ACC-01 phần server | Hai tài khoản cùng user; user khác đăng nhập | Số dư trả đúng account/JWT; account MARGIN/SUSPENDED vẫn đọc được lịch sử | PASS |
| Valuation | NAV=cash+blocked+stock; P/L theo tổng giá vốn | Decimal chính xác; mẫu số 0 trả null; danh mục phẳng, bỏ quantity=0 | PASS |
| BUY/CANCEL → assets | BUY chờ giữ 10,015,000; hủy hai lần | Cash/blocked/NAV đúng, không cấp lại hoặc giải tỏa lặp | PASS |
| BUY/MATCH → assets | Mua 100×99,000, phí 14,850 | Cash 990,085,150; stock 9,900,000; NAV 999,985,150; pending 100 | PASS |
| T+2 → holdings | Settlement đến hạn chạy hai lần | Available 100, pending 0, không tăng lặp | PASS |
| SELL/CANCEL → holdings | Bán chờ giữ 100 CP, hủy rồi bán khớp | Blocked không bị tính vào pending; bán xong danh mục rỗng và tiền đúng phí/thuế | PASS |
| Contract | Roundtrip JSON fixture market/candle/watchlist/assets/portfolio; HALF_UP | Khớp fixture, không float; 1.005→1.01, -1.005→-1.01 | PASS |
| Hồi quy | Auth CP1, Admin và trading tests cũ | Full suite 114 passed | PASS |

## File kiểm thử mới

- `backend/tests/integration/conftest.py`: PostgreSQL/DB session/client/registration fixtures.
- `test_market_postgres.py`: paging/search/quote/chart/auth và trường hợp thiếu mã/giá tham chiếu 0.
- `test_watchlist_postgres.py`: ownership, legacy, lặp và đồng thời.
- `test_assets_postgres.py`: định giá, ownership, chuyển tài khoản và mua/bán/hủy/T+2 thực thi.
- `backend/tests/unit/test_read_contracts.py`: Decimal và schema khớp fixture của frontend.

## HTTP smoke qua Uvicorn thật

Uvicorn tại `127.0.0.1:18004`, database demo riêng, client httpx qua TCP;
không override dependency:

```text
register 201 -> accounts 200
market/search 200 -> detail 200 -> chart 1M/3M/6M 200
watchlist add 201 -> add lại cùng ID -> list 200
BUY 201 COMPLETED -> assets/portfolio 200 với NAV đúng phí và pending 100
watchlist delete 204 -> delete lại 204 -> list rỗng
HTTP smoke PASS
```

Không ghi token/password vào bằng chứng. Kịch bản search FPT tìm theo cả mã và tên công ty,
vì vậy có thể trả nhiều công ty có tên chứa FPT; không giả định chỉ đúng một kết quả.

## Sửa phụ trợ cần thiết

Seed cũ insert giao dịch lịch sử trực tiếp trong khi trigger mới của Tuệ yêu cầu đã giữ tiền/CP.
Lượt dựng DB trống ban đầu bị lỗi `ck_portfolio_qty` tại một giao dịch SELL lịch sử.
Đã thêm reserve cash/blocked shares trước từng fill lịch sử trong `data/postgres/05_seed_trading.sql`;
không thay trading service/trigger. Sau sửa migrate/seed DB trống và regression seed đều qua.

## Bàn giao và giới hạn

- Phần báo cáo LB đã có tại [TV4_LB_BACKEND](../reports/TV4_LB_BACKEND.md).
- Cách chạy/API tại [backend README](../../backend/README.md); schema sinh trong `backend/openapi.json`.
- Workflow `checks` trên `traidep` chạy PostgreSQL 16/Python 3.13:
  [GitHub Actions](https://github.com/haphcc/StockMate/actions?query=branch%3Atraidep).
- Các ca UI màu/loading/cache, frontend tự refresh token, thiết bị thật, APK và payOS do chủ phần
  thử riêng. Chưa ghi PASS cho Flutter/APK hoặc cho mọi invariant/concurrency của trading engine.
- BE-04/vnstock/LIVE thuộc sau demo theo MVP_SCOPE, chưa triển khai.
- Backend/demo report của LB đã có code và bằng chứng; trạng thái **Chờ bàn giao** cho Sơn/Me/Châu,
  không dùng kết quả này để đánh dấu tất cả chặng của toàn nhóm là Xong.
