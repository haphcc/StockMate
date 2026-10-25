# Database: baseline, seed và phần cần hoàn thiện

Chủ: TV1 Phuoc; Tuệ cung cấp luật/routine giao dịch; LB cung cấp ORM/query.

## Hai đường chạy khác nhau

1. **Đường nhóm dùng từ bây giờ:** `alembic upgrade head` trên DB trống, sau đó seed_demo một lần.
2. **Script prototype cũ:** `data/postgres/00_run_all.sql` chạy DROP TABLE rồi dựng lại.
   Chỉ dùng DB bỏ được, không chạy vào database đang phát triển hoặc dùng chung.

Baseline `backend/alembic/versions/0001_baseline.py` dùng SQL snapshot bất biến trong
`backend/alembic/sql/0001_*.sql`; đã bỏ các lệnh DROP TABLE khỏi snapshot schema.
Baseline từ chối nếu một trong 9 bảng ứng dụng đã tồn tại. Migration không seed dữ liệu.
API readiness chỉ SELECT 1; không thay cho kiểm tra schema hay engine.

## Đã có DB prototype thì làm gì

- Giữ nguyên DB đó; tạo DB tên mới để thử baseline. Ví dụ DB riêng `stock_exchange_dev2`:

```powershell
docker compose exec db createdb -U postgres stock_exchange_dev2
```

- Backend local: đổi DATABASE_URL trong .env sang DB mới, chạy migrate rồi seed.
- Docker API: đổi DATABASE_URL trong compose sang DB mới và recreate riêng API.
- Không dùng `alembic stamp head` để bỏ qua khác biệt schema. Đối chiếu/backfill cần kế hoạch riêng.
- Không tự chạy `docker compose down -v`; volume là dữ liệu của cả nhóm.

## Viết thay đổi mới

1. `cd backend`; `python -m alembic revision -m "trading invariants"`.
2. Phuoc điền SQL DDL/function/procedure ở revision 0002+; có upgrade/downgrade rõ ràng.
3. Test từ DB trống và từ DB đã seed; dữ liệu cũ phải backfill được.
4. Tuệ kiểm tra luật, LB cập nhật mapping/schema bị ảnh hưởng, Châu chạy regression.
5. Sau baseline đã dùng, không sửa 0001/snapshot để lách việc tạo migration mới.

`--autogenerate` hiện bị chặn có chủ ý: chưa map đủ 9 bảng nên metadata rỗng có thể sinh DROP.
LB chỉ mở lại khi đầy đủ Base.metadata/import models và có bước kiểm tra migration thủ công.
Không dùng `Base.metadata.create_all()` thay cho Alembic trên môi trường nhóm.

## Khoảng trống SQL phải xử lý ở TR-01/02/03

| Hiện trạng baseline | Thay đổi đích | Chủ |
|---|---|---|
| Khớp BUY trừ cash, không xử lý reserve đã giữ | Routine reserve/release/apply khớp đúng CASH-01 | Tuệ + Phuoc |
| Không có blocked_quantity riêng | Thêm cột, constraint và backfill theo lệnh SELL chờ | Phuoc |
| T+2 đợi toàn bộ mua chưa đến hạn | Ledger từng đợt mua + trạng thái settled; job idempotent | Tuệ + Phuoc |
| Fee/tax/net do seed tính, DB tin số gửi vào | Routine tính Decimal từ dữ liệu gốc; không tin client | Tuệ |
| Chưa có client_order_id | UUID unique theo account, payload identity; backfill lệnh cũ | Phuoc + Tuệ |
| LEAST/GREATEST che khớp quá lượng/bán quá khả dụng | Kiểm tra/ràng buộc và rollback khi vi phạm | Tuệ |
| Trần/sàn dùng tick tại giá tham chiếu | Đúng tick vùng giá kết quả, test ngưỡng 10k/50k | Phuoc |
| Thông báo chỉ sinh từ seed | Sinh notification trong transaction nghiệp vụ | Tuệ |
| Margin/MP trong seed | Chỉ đọc lịch sử; chỉ CASH/LO cho giao dịch mới | LB + Tuệ |

Lưu số tiền reserve theo lệnh hoặc dẫn xuất chính xác từ limit/remaining + fee; chọn một cách,
ghi trong migration để hủy/khớp không phụ thuộc giá thị trường mới. Ledger là bảng mới được phép;
"9 bảng" là số ở baseline, không phải giới hạn cứng khi sửa nghiệp vụ.

## Seed

`python -m scripts.seed_demo` chạy 03–07 trong một transaction, khóa advisory chống chạy đồng thời,
từ chối DB đã có dữ liệu, thay hash mật khẩu mẫu bằng bcrypt thật. Không sửa balance thủ công để
che lỗi engine. Thay schema ảnh hưởng seed thì Phuoc cập nhật seed tương ứng trong cùng PR.

`09_check.sql` là các query quan sát, chưa phải test tự động fail-on-assert.
Châu cần integration tests cho bất biến và trường hợp đồng thời trong ACCEPTANCE_TESTS.

## Các bất biến phải kiểm tra

- Cash/blocked/available/blocked_quantity/pending_quantity không âm.
- quantity = available + blocked_quantity + pending_quantity.
- NAV = cash + blocked + SUM(quantity × current_price).
- Tổng số lượng portfolio = BUY - SELL đã khớp.
- Lệnh terminal không thay đổi filled_quantity; tổng fill không vượt quantity.
- Gửi lại UUID/worker/settlement không lặp tác động.
- Bất kỳ lỗi giữa chừng đều rollback cả tiền, cổ phiếu, lệnh, transaction và notification.
