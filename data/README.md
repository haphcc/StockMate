# Cơ sở dữ liệu — App giao dịch chứng khoán (Flutter + FastAPI + PostgreSQL)

Bộ script trong `data/postgres/` tạo đầy đủ schema và dữ liệu mẫu theo mô hình Entity
đã thiết kế, mô phỏng thị trường chứng khoán Việt Nam (HOSE / HNX / UPCOM).

## 1. Chạy

```bash
# Tạo database
createdb -h localhost -U postgres stock_exchange
# hoặc bằng Docker:
# docker run -d --name pg-stock -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16
# docker exec -it pg-stock createdb -U postgres stock_exchange

cd data/postgres
psql -h localhost -U postgres -d stock_exchange -f 00_run_all.sql   # tạo + nạp dữ liệu
psql -h localhost -U postgres -d stock_exchange -f 09_check.sql     # kiểm tra + ví dụ truy vấn
```

`00_run_all.sql` chạy lần lượt 8 file; chạy lại được nhiều lần (file 01 có `DROP TABLE ... CASCADE`).

## 2. Các file

| File | Nội dung |
|------|----------|
| `01_schema.sql` | 9 bảng, khóa ngoại, CHECK constraint, index |
| `02_functions_triggers.sql` | Bước giá, biên độ, trần/sàn; trigger khớp lệnh; định giá lại danh mục |
| `03_seed_stocks.sql` | 83 mã: 64 HOSE, 13 HNX, 6 UPCOM (tên công ty, ngành, KLNY, giá) |
| `04_seed_customers.sql` | 10 khách hàng, 13 tài khoản đầu tư, 27 dòng watchlist |
| `05_seed_trading.sql` | 58 lệnh đặt → sinh ra giao dịch khớp, danh mục và số dư |
| `06_seed_price_history.sql` | ~131 phiên OHLCV cho mỗi mã (≈ 10.900 dòng) để vẽ biểu đồ nến |
| `07_seed_notifications.sql` | Thông báo khớp lệnh, sổ lệnh, cảnh báo giá, hệ thống |
| `08_views.sql` | 6 view khớp với 6 màn hình của app |

## 3. Quy tắc thị trường đã được cài trong database

| Quy tắc | Cách cài đặt |
|---------|--------------|
| Biên độ dao động: HOSE ±7%, HNX ±10%, UPCOM ±15% | `fn_price_band()` |
| Bước giá HOSE: <10.000đ → 10đ; 10.000–49.950đ → 50đ; ≥50.000đ → 100đ; HNX/UPCOM → 100đ | `fn_price_tick()` |
| Giá trần / giá sàn tự tính từ giá tham chiếu | trigger `trg_stocks_price_limits` |
| Khớp lệnh → cập nhật danh mục (giá vốn bình quân gia quyền), trừ/cộng tiền, đổi trạng thái lệnh | trigger `trg_transaction_apply` |
| Giá thị trường đổi → định giá lại `current_value` / `profit_loss` của mọi danh mục | trigger `trg_stocks_reprice` |
| Chu kỳ thanh toán T+2 (cổ phiếu chưa về chưa được bán) | `available_quantity` + `sp_settle_pending_shares()` |
| Phí giao dịch 0,15%; thuế TNCN 0,1% khi bán | tính trong `05_seed_trading.sql`, lưu ở `transactions.transaction_fee` / `tax_amount` |
| Tiền phong tỏa cho lệnh mua chờ khớp | `investment_accounts.blocked_balance` |

Nghĩa là backend FastAPI chỉ cần `INSERT` vào `transactions`, database sẽ tự lo phần còn lại.

## 4. View ↔ màn hình app

| View | Màn hình Flutter |
|------|------------------|
| `v_market_board` | Bảng giá (kèm `price_state`: CEILING/FLOOR/UP/DOWN/REFERENCE để tô màu tím/xanh lam/xanh/đỏ/vàng) |
| `v_portfolio_detail` | Danh mục (lãi/lỗ từng mã, số lượng chờ về T+) |
| `v_account_summary` | Tài sản (tiền + chứng khoán + tổng lãi/lỗ) |
| `v_order_book` | Sổ lệnh |
| `v_transaction_history` | Lịch sử giao dịch |
| `v_watchlist_detail` | Danh mục quan tâm |

## 5. Tài khoản demo

| Email | Số TK | Ghi chú |
|-------|-------|---------|
| an.nguyen@gmail.com | 068C100001, 068C100002 | 1 TK thường + 1 TK ký quỹ |
| cuong.le@gmail.com | 068C100004, 068C100005 | Danh mục lớn, nhiều mã |
| khanh.dang@gmail.com | 068C100009 | Tài khoản lớn nhất, lãi nhiều |
| lam.bui@gmail.com | 068C100010 | Vốn nhỏ, cổ phiếu giá thấp |
| mai.do@gmail.com | 068C100013 | `status = PENDING` (chưa eKYC), có lệnh bị từ chối |

Mật khẩu demo: `Matkhau@123`.
**`password_hash` trong file 04 là chuỗi mẫu đúng định dạng bcrypt, không phải hash thật** —
trước khi bật đăng nhập hãy sinh lại:

```python
from passlib.context import CryptContext
pwd = CryptContext(schemes=["bcrypt"])
print(pwd.hash("Matkhau@123"))
```

```sql
UPDATE customers SET password_hash = '<hash vừa sinh>';
```

## 6. Lưu ý khi dùng với SQLAlchemy

- Tiền dùng `NUMERIC(20,2)`, giá dùng `NUMERIC(12,2)` → map sang `Decimal`, **đừng dùng `float`**.
- Đơn vị giá là **đồng** (VD: `62800` = 62.800đ). Nếu app hiển thị theo nghìn đồng thì chia 1.000 ở tầng UI.
- Các cột trạng thái dùng `VARCHAR + CHECK` thay vì `ENUM` của Postgres để dễ migrate bằng Alembic;
  phía Python khai báo `Enum` trong code và để `native_enum=False`.
- `stocks.current_price` là nguồn giá duy nhất: cập nhật qua `CALL sp_update_market_price('FPT', 101500);`
  là toàn bộ danh mục của mọi khách hàng được định giá lại.
- Giá và khối lượng trong `03` / `06` là **dữ liệu mô phỏng cho môi trường DEV/DEMO**, không phải
  giá thị trường thực tế tại thời điểm chạy.
