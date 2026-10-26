# Châu — Kiểm thử, tiến độ và báo cáo

**Bắt đầu tại:** docs/WORK_BOARD.md và [ACCEPTANCE_TESTS](../ACCEPTANCE_TESTS.md).

1. Thử cài/chạy theo [SETUP](../SETUP.md); ghi phần thiếu hoặc chưa chạy trong docs/qa/.
2. Khi Phuoc/LB có backend, thử dựng DB, đăng ký/đăng nhập và gọi API.
3. Thử app bằng hai người dùng để phát hiện lộ/lẫn dữ liệu; kiểm tra thị trường và tài sản.
4. Cùng Tuệ test mua/bán/hủy, gửi trùng, cạnh tranh, phí/thuế và T+2.
5. Ghi lỗi cho đúng chủ file, thử lại bản sửa rồi cập nhật tiến độ.
6. Nhận APK từ Phuoc; chạy demo trên emulator/máy thật, ghép báo cáo/slide từ phần mỗi người gửi.
7. Xây dựng Frontend Tab Quản trị ẩn (Admin Management Tab) trên Mobile App:
   - Trong `mobile/lib/features/home/screens/home_shell.dart`, kiểm tra quyền của người dùng đang đăng nhập (`user.role == 'ADMIN'`).
   - Nếu là ADMIN, tự động hiển thị thêm một Tab ẩn "Quản trị" trên thanh Bottom Navigation Bar (người dùng thường CUSTOMER sẽ không thấy tab này).
   - Dựng các màn hình quản trị CRUD toàn diện trong `mobile/lib/features/admin/`:
     + Tổng quan quản trị (Admin Dashboard).
     + Quản lý Khách hàng & Tài khoản: xem danh sách, form tạo khách hàng mới, sửa thông tin, đặt lại mật khẩu, đổi role, đổi trạng thái (ACTIVE/LOCKED), và **nút xóa tài khoản khách hàng** (kèm hộp thoại xác nhận cảnh báo cascade).
     + Quản lý Mã cổ phiếu: danh sách mã, form thêm mã mới, sửa giá trần/sàn/tham chiếu, đổi trạng thái (ACTIVE/SUSPENDED), xóa mã cổ phiếu.
     + Quản lý Lệnh & Giao dịch: tra cứu sổ lệnh toàn hệ thống, can thiệp hủy lệnh chờ, xem lịch sử giao dịch.
     + Quản lý Danh mục & Tài sản: điều chỉnh số lượng cổ phiếu/tiền khi cần can thiệp hỗ trợ.
     + Quản lý Lịch sử giá & Biểu đồ: thêm/sửa/xóa nến OHLCV.
     + Soạn & Gửi Thông báo: tạo thông báo broadcast toàn sàn hoặc gửi thông báo riêng cho từng khách hàng; xóa thông báo.
   - Kết nối với các API `/api/admin/...` do Phuoc cung cấp.

**File phụ trách:** backend/tests/, mobile/test/, mobile/integration_test/, mobile/lib/features/admin/,
docs/qa/ và WORK_BOARD.md. Người viết tính năng vẫn phải tự kiểm tra phần mình.

**Bàn giao đầu tiên:** kết quả setup và danh sách lỗi rõ cách tái hiện.
Chưa có implementation thì ghi chưa chạy; CI khung xanh không có nghĩa tính năng đã xong.

Mẫu lỗi: việc đang thử → các bước → mong đợi → thực tế → người sửa → kết quả thử lại.
Mã TODO tương ứng: QA-01, QA-02, QA-03.
Theo [PLAN](../PLAN.md); phần mỗi người viết trong báo cáo ở [TASK_ASSIGNMENT](../TASK_ASSIGNMENT.md).
