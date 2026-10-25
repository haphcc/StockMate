# Phạm vi bản demo đầu tiên

Đây là baseline làm việc đã chọn từ đánh giá repo, có thể điều chỉnh bằng PR trước khi triển khai
phần bị ảnh hưởng. Đây là phần thu gọn của PLAN, không phải mô phỏng đầy đủ quy chế sở giao dịch.

## Bắt buộc

| Chức năng | Hành vi phải giao | Chủ |
|---|---|---|
| Đăng ký | Họ tên + email + SĐT + password; tạo CASH account, cấp 1 tỷ tiền giả lập một lần | LB + Sơn |
| Phiên đăng nhập | Email/password JSON, access + refresh JWT, tự refresh một lần khi 401 | LB + Sơn |
| Tài khoản | Danh sách của chính khách hàng; chọn account theo `account_id`; chỉ CASH được giao dịch | LB + Sơn |
| Thị trường | HOSE/HNX/UPCOM, tìm kiếm, chi tiết mã, OHLCV; giá DEMO là mặc định | LB + Me |
| Tài sản | Tiền khả dụng/phong tỏa, NAV, danh mục, giá vốn và lãi/lỗ | LB + Sơn |
| Watchlist | Một danh sách mặc định; thêm/xóa mã, không có cảnh báo giá tự động | LB + Me |
| Giao dịch | BUY/SELL LO, bội số 100, khớp toàn bộ nếu đạt điều kiện; chờ hoặc hủy nếu chưa khớp | Tuệ + Me |
| Thanh toán | Cổ phiếu mua về sau 2 ngày làm việc mô phỏng; tiền bán cộng ngay | Tuệ + Phuoc |
| Thông báo | Trong app: đặt/khớp/hủy; danh sách và đánh dấu đã đọc | Tuệ + Me |
| Demo | APK Android, kịch bản có thể tái hiện ngoài giờ giao dịch thật | Phuoc + Châu |

## Để sau G4

- Margin, vay/nợ/lãi, eKYC thật, nạp/rút tiền thật.
- MP/ATO/ATC, khớp một phần, đấu giá, ưu tiên sổ lệnh, tự hết hạn cuối phiên.
- Google/Apple, OTP, sinh trắc học, khôi phục/đổi mật khẩu, sửa hồ sơ.
- Push notification, tin tức, chỉ số VN-Index/VN30 trực tiếp, cảnh báo giá theo ngưỡng.
- SLA real-time 5–10 giây, WebSocket; `vnstock` là đầu việc mở rộng sau luồng demo ổn định.
- Bản phát hành App Store/iOS; build iOS vẫn cần macOS + Xcode.

Ẩn/vô hiệu hóa nút thuộc phần để sau và ghi rõ "Sắp có". Không cho nút Google/sinh trắc học gọi
login thường rồi thông báo đăng nhập bằng các phương thức chưa triển khai.

## Giản lược được chấp nhận

- Phiên mô phỏng luôn mở khi chạy demo; lệnh chờ giữ đến khi khớp hoặc chủ tài khoản hủy.
- Ngày làm việc T+2 chỉ bỏ thứ Bảy/Chủ nhật. Chưa có lịch nghỉ lễ; UI/tài liệu ghi "T+2 mô phỏng".
- Seed cũ chứa MARGIN và MP: chỉ để đọc lịch sử; không được dùng chúng để đặt lệnh MVP.
- Giá demo lấy từ seed/cập nhật thủ công bằng công cụ DEV; không tự nhận là giá thị trường hiện tại.
- Logout xóa token trên thiết bị; chưa có thu hồi refresh token phía server.
- Giá mua vốn bình quân chưa gồm phí; phí trừ vào tiền và hiện riêng ở lịch sử giao dịch.

## Điều kiện nghiệm thu

Một người mới làm theo SETUP dựng được môi trường; chạy đủ G0 → G4 trong START_HERE.
Châu dùng [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md) để ghi pass/fail và bằng chứng.
