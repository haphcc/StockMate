# Kế hoạch StockMate

Mục tiêu: có app Android demo được luồng **đăng ký → đăng nhập → xem cổ phiếu → mua/bán → xem tài sản**.
Giữ phân công tại [TASK_ASSIGNMENT](TASK_ASSIGNMENT.md); cập nhật tiến độ tại [WORK_BOARD](WORK_BOARD.md).

## Chặng 1 — Chạy nền và đăng nhập

- Phuoc: dựng database, migration và dữ liệu mẫu; chuẩn bị môi trường backend.
- LB: viết FastAPI, kết nối DB, health và API đăng ký/đăng nhập/tài khoản.
- Sơn: sửa form, xử lý token và nối đăng nhập Flutter với API.
- Me (TV3): dựng bảng giá/chi tiết bằng JSON mẫu trong lúc chờ API.
- Tuệ: cùng Phuoc chốt cách giữ tiền/cổ phiếu và quy tắc mua/bán.
- Châu: thử cài từ đầu và kiểm tra đăng ký/đăng nhập.

**Qua chặng khi:** một máy khác dựng được môi trường; app đăng ký, đăng nhập và lấy đúng tài khoản qua API.

## Chặng 2 — Xem thị trường và tài sản

- LB: API bảng giá, tìm kiếm, chi tiết, biểu đồ, watchlist và tài sản/danh mục.
- Me (TV3): nối bảng giá/chi tiết/biểu đồ/watchlist với API.
- Sơn: nối dashboard, chọn tài khoản và danh mục với API.
- Phuoc + Tuệ: hoàn thiện schema/routine và test cho giao dịch chặng 3.
- Châu: kiểm tra dữ liệu hiển thị và việc tách dữ liệu giữa người dùng.

**Qua chặng khi:** giá và tài sản lấy từ DB qua API; thêm/xóa watchlist đúng; đổi tài khoản không lẫn dữ liệu.

## Chặng 3 — Giao dịch và demo

- Tuệ + Phuoc: đặt/khớp/hủy lệnh, giữ/giải tỏa tiền/cổ phiếu, phí/thuế, T+2 và thông báo.
- Me (TV3): nối màn hình đặt lệnh, sổ lệnh, lịch sử và thông báo.
- Sơn + LB: hỗ trợ tích hợp; cập nhật tài sản sau giao dịch và sửa lỗi phần mình.
- Châu: kiểm tra trọn luồng, tổng hợp báo cáo/slide; Phuoc build APK.

**Qua chặng khi:** mua/bán/hủy đúng số tiền và cổ phiếu, T+2 không xử lý lặp; APK chạy được kịch bản demo.

Chưa đặt ngày cố định; Phuoc chốt thời gian với nhóm. Có thể chuẩn bị phần độc lập song song,
nhưng phải thử bàn giao trước khi coi một chặng là xong.

## Phạm vi demo

Dùng giá DEMO, tài khoản CASH, lệnh LO theo lô 100 cổ phiếu; có đăng nhập, thị trường,
tài sản, watchlist, giao dịch và thông báo trong app. Chi tiết: [MVP_SCOPE](MVP_SCOPE.md).

Sau demo mới xem xét vnstock/giá trực tiếp, margin, MP/ATO/ATC, đăng nhập Google/OTP và push notification.
Code Flutter và SQL gốc được giữ. Backend CP1 và migration/seed đã có code thực thi;
trạng thái bàn giao, kể cả các phần còn TODO, xem WORK_BOARD và hướng dẫn từng thành viên.

Khi code mới tra [API_CONTRACT](API_CONTRACT.md) về JSON/API,
[BUSINESS_RULES](BUSINESS_RULES.md) về tiền/giao dịch và [ACCEPTANCE_TESTS](ACCEPTANCE_TESTS.md) để kiểm thử.
