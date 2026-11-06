# Bảng Ghi Nhận Lỗi (Bugs)

| Bug | Trạng thái | Người xử lý |
| :--- | :--- | :--- |
| Khóa payOS nằm trong `.env.example` và `config.py` | Đã xác nhận (đọc code) | Phuoc |
| `compose.yaml` mật khẩu DB và `SECRET_KEY` ghi cứng, lệch `.env.example` | Đã xác nhận | Phuoc |
| `smallestKeySize` trong AndroidManifest (nghi ngờ) | Cần xác nhận bằng `flutter build apk` | Son/Me |
| Thiếu core library desugaring (nghi ngờ) | Cần xác nhận bằng `flutter build apk` | Son/Me |
| `ACCEPTANCE_TESTS.md` ghi 83 mã (thực tế 90), `WORK_BOARD.md` lỗi thời | Đã xác nhận | Phuoc/LB |
| OpenAPI snapshot stale | Không tái hiện trên máy QA (đo được: `OpenAPI snapshot matches app`) | LB |

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