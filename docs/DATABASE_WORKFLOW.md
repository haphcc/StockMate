# Database: phần gốc, phần khung và việc phải tự làm

Chủ: TV1 Phuoc; Tuệ phụ trách luật/routine giao dịch; LB phụ trách ORM/query.

## Hiện có gì

- data/postgres giữ nguyên SQL prototype của nhóm trước bước chuẩn bị.
- backend/alembic/sql/0001_*.sql và migration 0001–0003 đã có implementation.
- backend/scripts/seed_demo.py đã có seed demo với bcrypt thật và kiểm tra DB có dữ liệu.
- TV4 CP1 đã có DB session và health thực thi. Migration/seed/auth đã được thử trên PostgreSQL
  riêng; hướng dẫn hiện hành ở [backend README](../backend/README.md), bằng chứng
  [TV4_CP1](qa/TV4_CP1.md). Nghiệp vụ trading vẫn cần Phuoc/Tuệ kiểm thử theo các chặng sau.

Việc gỡ code khỏi repo không xóa database/volume đã tồn tại trên máy nào.

## ENV-01 — Phuoc tự triển khai

1. Đọc prototype; thống nhất tên bảng/cột, kiểu tiền và mối quan hệ với LB/Tuệ.
2. Tạo PostgreSQL DEV riêng và viết cấu hình Docker/connection.
3. Khởi tạo Alembic thật; điền env/template/config và revision 0001 có upgrade/downgrade.
4. Tự viết SQL ban đầu sau review; chặn chạy baseline lên DB đã có bảng app.
5. Tự viết seed an toàn: một transaction, chống chạy đồng thời, từ chối DB có dữ liệu, bcrypt hash thật.
6. Châu viết test dựng từ DB trống, dữ liệu seed, seed lần hai bị từ chối và migrate lần hai không đổi.
7. Thêm các lệnh kiểm tra này vào CI rồi bàn giao kết nối cho LB/Tuệ.

Các mục ENV-01 bên trên là checklist trách nhiệm, không phải khẳng định mọi mục còn TODO.
Không dùng Base.metadata.create_all thay cho migration trên môi trường nhóm.
Chỉ bật autogenerate khi đã map đủ metadata và review SQL sinh ra.
Sau khi nhóm phát hành baseline thật, giữ cố định migration đó và tạo revision mới cho thay đổi tiếp theo.

## Khoảng trống của SQL prototype gốc

| Phần cần làm | Chủ |
|---|---|
| Reserve/release tiền theo lệnh BUY, tránh trừ hai lần khi khớp | Tuệ + Phuoc |
| blocked_quantity, constraint và backfill cho SELL chờ | Phuoc + Tuệ |
| Ledger từng đợt mua, settlement idempotent, ngày làm việc | Tuệ + Phuoc |
| Tính fee/tax/net ở server/routine, không tin client | Tuệ |
| client_order_id unique theo account, kiểm tra payload lặp | Phuoc + Tuệ |
| Chặn khớp quá lượng/bán quá khả dụng; rollback thay vì clamp | Tuệ |
| Trần/sàn đúng bước giá tại ngưỡng 10k/50k | Phuoc |
| Notification trong cùng transaction nghiệp vụ | Tuệ |
| Chỉ CASH/LO cho giao dịch mới; Margin/MP cũ chỉ đọc | LB + Tuệ |

Nhóm có thể đưa invariant vào 0001 thật hoặc revision sau theo thiết kế đã review;
không suy ra các invariant trading đã được đáp ứng chỉ từ việc migration chạy thành công.

## Dữ liệu và kiểm thử

- Không chạy script prototype trong data/postgres/ lên DB đang dùng: script gốc có DROP.
- Không tự xóa volume hoặc stamp head để bỏ qua khác biệt schema.
- Hash mật khẩu trong seed gốc là mẫu; Phuoc phải sinh hash thật trước khi LB test login.
- Nếu chạy SQL thô qua psycopg, chú ý ký tự % và toán tử modulo khi không có tham số.
- Test bất biến tiền/số lượng, ownership, duplicate, hai request cạnh tranh và rollback toàn bộ.
