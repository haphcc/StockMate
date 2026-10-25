# Phuoc — Database và môi trường

**Bắt đầu tại:** backend/alembic/, backend/scripts/seed_demo.py, compose.yaml.
SQL trong data/postgres là prototype gốc; file mới hiện là TODO.

1. Cùng LB/Tuệ chốt bảng, cột và kiểu tiền. Đọc [DATABASE_WORKFLOW](../DATABASE_WORKFLOW.md).
2. Tự viết cấu hình PostgreSQL/Docker, Alembic và migration; dùng DB DEV mới.
3. Viết seed dữ liệu mẫu, hash mật khẩu thật; chạy lại phải từ chối thay vì xóa dữ liệu.
4. Cho LB/Tuệ thông tin kết nối; cùng Châu thử dựng lại từ đầu.
5. Cùng Tuệ thêm schema/routine cho giữ tiền/cổ phiếu, khớp/hủy và T+2.
6. Khi luồng app đã ổn, bật test cần thiết trong CI và build APK cho Châu demo.

**File phụ trách:** data/postgres/, backend/alembic/, backend/scripts/seed_demo.py,
backend/Dockerfile, compose.yaml, .github/workflows/, mobile/android/ và ios/.

**Bàn giao đầu tiên:** người khác dựng được DB mới và nạp dữ liệu bằng hướng dẫn của Phuoc.
Không chạy script DROP/reset lên DB đang dùng. Chỉ đóng băng migration sau khi nhóm đã phát hành thật.

Mã TODO tương ứng: ENV-01, TR-01 (phối hợp Tuệ), ENV-02.
Theo dõi tại [WORK_BOARD](../WORK_BOARD.md); phần báo cáo tại [TASK_ASSIGNMENT](../TASK_ASSIGNMENT.md).
