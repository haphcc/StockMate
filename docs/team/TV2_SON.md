# Sơn — Flutter chung, đăng nhập và tài sản

**Bắt đầu tại:** mobile/lib/features/auth/, core/network/ và data/models/.

1. Sửa model tiền theo JSON mẫu; làm helper tiền chính xác để Me (TV3) dùng chung.
2. Sửa form đăng ký đủ họ tên/email/SĐT/password; thêm validation và xử lý lỗi.
3. Khi LB bàn giao API, viết datasource/repository, lưu token và refresh; nối đăng nhập thật.
4. Bổ sung chọn mock/API và chọn tài khoản; nối dashboard/portfolio với API của LB.
5. Gắn màn hình Me (TV3) vào router; cập nhật tài sản sau mua/bán/hủy.
6. Chạy analyze/test; thử logout/đăng nhập người khác để tránh còn dữ liệu phiên cũ.
7. Giao diện nạp tiền payOS: thêm nút "Nạp tiền" ở màn hình Dashboard/Account; dựng dialog/screen nhập số tiền, gọi API deposit của Phuoc và hiển thị mã VietQR thanh toán tự động; cập nhật lại số dư sau khi quét mã thành công.

**File phụ trách:** mobile/lib/core/, providers/, features/auth/, home/, portfolio/;
models và repositories phần auth/account/portfolio và deposit (payOS). Sơn giữ router/network/file dùng chung.

**Bàn giao đầu tiên:** app đăng ký/đăng nhập bằng API; Me (TV3) dùng được helper/network/router.
App hiện useMock=true cố định; Sơn tự viết lựa chọn môi trường, chưa có sẵn cờ chuyển sang API.

Mã TODO tương ứng: FE-01, FE-02, FE-04.
Tra [API_CONTRACT](../API_CONTRACT.md) và [JSON mẫu](../contracts/examples.json) khi code;
cập nhật [WORK_BOARD](../WORK_BOARD.md).
