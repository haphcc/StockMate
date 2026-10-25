# Me — TV3: thị trường và giao dịch trên Flutter

Me là tên riêng của thành viên TV3, không phải người yêu cầu chuẩn bị repo.
**Bắt đầu tại:** mobile/lib/features/market/ và data/models/stock_model.dart.

1. Dùng helper tiền/network/router do Sơn giữ; dựng bảng giá/chi tiết với JSON mẫu khi chờ API.
2. Làm tìm kiếm, biểu đồ và watchlist; nối API thị trường khi LB bàn giao.
3. Làm form mua/bán và sổ lệnh; nối API đặt/khớp/hủy của Tuệ.
4. Làm lịch sử và thông báo; phối hợp Sơn cập nhật tài sản sau giao dịch.
5. Hiển thị loading/trống/lỗi rõ ràng; chỉ báo thành công khi API xác nhận.
6. Đưa Châu thử luồng xem giá → mua/bán → hủy → xem lịch sử.

**File phụ trách:** mobile/lib/features/market/, watchlist/, order/, transaction/, notification/;
models/datasources/repositories tương ứng. Trao đổi với Sơn trước khi sửa router/model dùng chung.

**Bàn giao đầu tiên:** bảng giá từ repository, chọn mã mở đúng chi tiết; sau đó nối API của LB.
Khi gửi lại cùng một lệnh do timeout, giữ cùng client_order_id; không tự sửa số dư ở client.

Mã TODO tương ứng: FE-03, FE-04, FE-05.
Tra [API_CONTRACT](../API_CONTRACT.md) và [JSON mẫu](../contracts/examples.json) khi code;
cập nhật [WORK_BOARD](../WORK_BOARD.md).
