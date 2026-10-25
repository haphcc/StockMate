# Châu — Kiểm thử, tiến độ và báo cáo

**Bắt đầu tại:** docs/WORK_BOARD.md và [ACCEPTANCE_TESTS](../ACCEPTANCE_TESTS.md).

1. Thử cài/chạy theo [SETUP](../SETUP.md); ghi phần thiếu hoặc chưa chạy trong docs/qa/.
2. Khi Phuoc/LB có backend, thử dựng DB, đăng ký/đăng nhập và gọi API.
3. Thử app bằng hai người dùng để phát hiện lộ/lẫn dữ liệu; kiểm tra thị trường và tài sản.
4. Cùng Tuệ test mua/bán/hủy, gửi trùng, cạnh tranh, phí/thuế và T+2.
5. Ghi lỗi cho đúng chủ file, thử lại bản sửa rồi cập nhật tiến độ.
6. Nhận APK từ Phuoc; chạy demo trên emulator/máy thật, ghép báo cáo/slide từ phần mỗi người gửi.

**File phụ trách:** backend/tests/, mobile/test/, mobile/integration_test/,
docs/qa/ và WORK_BOARD.md. Người viết tính năng vẫn phải tự kiểm tra phần mình.

**Bàn giao đầu tiên:** kết quả setup và danh sách lỗi rõ cách tái hiện.
Chưa có implementation thì ghi chưa chạy; CI khung xanh không có nghĩa tính năng đã xong.

Mẫu lỗi: việc đang thử → các bước → mong đợi → thực tế → người sửa → kết quả thử lại.
Mã TODO tương ứng: QA-01, QA-02, QA-03.
Theo [PLAN](../PLAN.md); phần mỗi người viết trong báo cáo ở [TASK_ASSIGNMENT](../TASK_ASSIGNMENT.md).
