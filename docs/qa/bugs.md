# Bảng Ghi Nhận Lỗi (Bugs)

| Bug | Trạng thái | Người xử lý |
| :--- | :--- | :--- |
| Khóa payOS nằm trong `.env.example` và `config.py` | Đã xác nhận (đọc code) | Phuoc |
| `compose.yaml` mật khẩu DB và `SECRET_KEY` ghi cứng, lệch `.env.example` | Đã xác nhận | Phuoc |
| `smallestKeySize` trong AndroidManifest (nghi ngờ) | Cần xác nhận bằng `flutter build apk` | Son/Me |
| Thiếu core library desugaring (nghi ngờ) | Cần xác nhận bằng `flutter build apk` | Son/Me |
| `ACCEPTANCE_TESTS.md` ghi 83 mã (thực tế 90), `WORK_BOARD.md` lỗi thời | Đã xác nhận | Phuoc/LB |
| OpenAPI snapshot stale | Không tái hiện trên máy QA (đo được: `OpenAPI snapshot matches app`) | LB |
| Backend nhận số dư tài khoản vô lý (blocked > cash, tổng tài sản < cash) | Chưa tái hiện | Phuoc |
| Mở tài khoản mới sau khi xóa một tài khoản khác bị 503 | Chưa tái hiện | Phuoc |
| Backend nhận giá trần < giá sàn và giá hiện tại ngoài biên độ khi sửa cổ phiếu | Chưa tái hiện | Phuoc |
---

## BUG-01: Khóa payOS bị commit
- **Việc đang thử:** Đọc cấu hình backend khi dựng môi trường.
- **Các bước:** Mở `backend/.env.example` và `backend/app/core/config.py`.
- **Mong đợi:** Không có khóa thật trong repo; các giá trị nhạy cảm phải lấy từ file `.env` cá nhân và để trống/mẫu trong repo.
- **Thực tế:** `PAYOS_CLIENT_ID`, `PAYOS_API_KEY`, `PAYOS_CHECKSUM_KEY` có giá trị dạng thật ở cả hai file (giá trị mặc định gán trực tiếp trong `config.py`).
- **Người sửa:** Phuoc (tạo lại khóa mới trên payOS, xóa bỏ giá trị mặc định trong code).
- **Kết quả thử lại:** Chưa.

---

## BUG-02: compose.yaml ghi cứng mật khẩu DB và SECRET_KEY lệch .env.example
- **Việc đang thử:** Khởi động dịch vụ cơ sở dữ liệu và cấu hình biến môi trường kết nối.
- **Các bước:** 
  1. Mở file `compose.yaml` ở thư mục gốc.
  2. So sánh thông tin biến môi trường của container `postgres` và service API với file `backend/.env.example`.
- **Mong đợi:** Mật khẩu kết nối PostgreSQL (`POSTGRES_PASSWORD`), `DATABASE_URL` và `SECRET_KEY` phải đồng bộ nhất quán giữa Docker Compose và file cấu hình mẫu `.env.example`, hoặc được nạp động qua biến môi trường thay vì gán cứng khác nhau.
- **Thực tế:** Trong `compose.yaml`, mật khẩu PostgreSQL và chuỗi `SECRET_KEY` đang bị gán cứng giá trị mặc định, không đồng bộ với thông số mẫu trong `backend/.env.example`, dễ gây lỗi xác thực khi khởi chạy hoặc kiểm thử môi trường mới.
- **Người sửa:** Phuoc (đồng bộ lại biến môi trường, sử dụng file `.env` chung hoặc chuẩn hóa giá trị kết nối giữa `compose.yaml` và `.env.example`).
- **Kết quả thử lại:** Chưa.

## BUG-03: Số dư tài khoản vô lý được chấp nhận
- Các bước: PUT /api/admin/accounts/{id} với cash_balance=100, blocked_balance=999999, total_asset_value=50.
- Mong đợi: bị từ chối (422 hoặc 409).
- Thực tế: 200 và lưu luôn.
- Người sửa: Phuoc.

## BUG-04: Mở tài khoản mới báo 503 sau khi xóa một tài khoản
- Các bước: mở tài khoản A1, mở A2, xóa A1, mở A3 cho cùng khách hàng.
- Mong đợi: A3 được tạo với số chưa dùng.
- Thực tế: 503 DATABASE_UNAVAILABLE. Nghi nguyên nhân: số tài khoản sinh bằng (đếm + 1) nên trùng số A2, lỗi trùng bị báo sai thành lỗi cơ sở dữ liệu.
- Người sửa: Phuoc.

## BUG-05: Sửa cổ phiếu nhận giá vô lý
- Các bước: PUT /api/admin/stocks/{id} với ceiling_price=10000, floor_price=30000; riêng PUT current_price=99999 khi trần là 21400.
- Mong đợi: bị từ chối.
- Thực tế: cả hai đều 200 và lưu.
- Người sửa: Phuoc.