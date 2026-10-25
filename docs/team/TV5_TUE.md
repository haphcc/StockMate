# TV5 — Tuệ: engine đặt/khớp/hủy, settlement và thông báo

Tra file: `python scripts/check_preparation.py --owner TV5`.
Đọc BUSINESS_RULES và DATABASE_WORKFLOW trước khi sửa trigger; SQL prototype gốc chưa phải engine hoàn chỉnh; Alembic hiện chỉ là TODO.

## TR-01 — Khóa luật bằng test và schema, bắt đầu ngay

**Input:** CASH-01/SHARE-01/STATE-01/SETTLE-01, schema hiện có; không cần chờ app.

1. Viết test case số tiền chính xác theo hai ví dụ BUY/SELL; xác định cần thêm cột/routine nào.
2. Cùng Phuoc thiết kế reserve theo order, blocked_quantity, UUID idempotency và ledger settlement.
3. Phuoc giữ migration files; Tuệ đưa SQL routine và review. Không hai người sửa cùng migration độc lập.
4. Map StockOrder/Transaction/Notification sau schema; lưu `client_order_id` và unique constraint đúng account.
5. Chốt tên/params routine với LB; endpoint gọi use case, CRUD không commit.

**File:** app/models/{stock_order,transaction,notification}.py; schemas/{trading,notifications}.py;
tests/unit/test_trading.py; SQL đóng góp vào revision Phuoc giữ.
**Xong khi:** migration do nhóm viết được review, test reserve/cancel/khớp có expected numbers, chưa gọi xong G3.

## TR-02 — Order service và matching sau BE-01 + TR-01

1. Nhận current_user/session từ LB; owner-filtered account/order. Khóa theo thứ tự BUSINESS_RULES.
2. Kiểm tra active/CASH/LO/lot/band/tick và sức mua/available sau khóa.
3. UUID cùng payload trả lệnh cũ, khác payload 409; không dùng check-before-insert thiếu unique constraint.
4. Một transaction đặt lệnh + reserve + notification; nếu quote đạt điều kiện, engine fill toàn bộ.
5. Engine BUY khớp khi quote≤limit, SELL quote≥limit, giá fill là quote server.
6. Routine DB tính fee/tax/net/apply và xử lý reserve; Python không tính lại lần hai.
7. Cancel PENDING giải tỏa, cancel lặp idempotent; completed trả 409.
8. Transactions là read-only phía client; không tạo endpoint cho client insert trực tiếp.
9. Orders/transactions page đúng account; notifications chỉ customer hiện tại.
10. Integration test PostgreSQL hai request cạnh tranh, cancel vs match, worker gọi lại và rollback giữa chừng.

**File:** services/{order,matching,notification}_service.py; crud/{orders,transactions,notifications}.py;
endpoints/{orders,transactions,notifications}.py; models/schemas trading; tests/unit/test_trading.py.
**Phối hợp:** Phuoc migration/routine; Châu integration test; Me UI payload/refresh state.
**Xong khi:** QA-ORD-01–09 và QA-NOT-01 pass bằng số thực tế; không che negative bằng clamp.

## TR-03 — T+2 từng đợt

1. Map settlement ledger sau revision Phuoc; tính ngày làm việc theo giờ Việt Nam.
2. Job nhận as_of_date; khóa/đánh dấu từng lot đã xử lý trong cùng transaction.
3. Giải phóng đúng lot đã đến hạn, không đợi mọi lot cùng mã; không mở khóa lượng đang blocked SELL.
4. Điền scripts/settle_shares.py CLI; gọi lần hai cùng ngày không thay đổi lần hai.
5. Test thứ Sáu → thứ Ba, hai lot về khác ngày, blocked SELL, timezone qua nửa đêm.
6. Ghi rõ T+2 mô phỏng bỏ cuối tuần, tiền bán cộng ngay; không mô tả là full settlement thật.

**File:** app/models/settlement.py; services/settlement_service.py; scripts/settle_shares.py;
tests/unit/test_settlement.py; SQL migration phối hợp Phuoc.
**Xong khi:** QA-SET-01/02/03 pass.

**PR đầu tiên:** `codex/TR-01-trading-invariants`.
**Bàn giao:** Me nhận JSON/error codes; LB nhận transaction ownership; Châu nhận seed cho cạnh tranh.
**Không làm:** auto fill bằng cách chỉ INSERT transactions rồi tin trigger cũ đã bao hết reserve/T+2.
