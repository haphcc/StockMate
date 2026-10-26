# LB — Backend chung và API đọc dữ liệu

**Bắt đầu tại:** backend/app/main.py, core/, db/, schemas/ và api/.
**Checkpoint 1:** backend đã triển khai và kiểm thử đăng ký/đăng nhập/refresh/me/accounts,
health và lỗi thống nhất; đang chờ Sơn/Châu thử bàn giao trên app.
Hướng dẫn chạy, URL và token: [backend README](../../backend/README.md).
Bằng chứng: [TV4_CP1](../qa/TV4_CP1.md).

1. Viết FastAPI app, cấu hình, DB session, lỗi thống nhất và health; phối hợp Phuoc về kết nối DB.
2. Viết model/schema, API đăng ký/đăng nhập/refresh/me và danh sách tài khoản.
3. Bàn giao JSON/URL cho Sơn; bàn giao xác thực và DB session cho Tuệ.
4. Viết API bảng giá, tìm kiếm, chi tiết/chart, watchlist, tài sản và danh mục cho Sơn/Me (TV3).
5. Kiểm tra tài nguyên thuộc người đăng nhập; không lộ tài khoản người khác.
6. Viết test và sinh OpenAPI khi app đã có; hỗ trợ Châu thử tích hợp.

**File phụ trách:** backend/app/main.py, core/, db/, api/deps.py;
endpoints/models/schemas/crud/services phần auth, accounts, market và watchlist;
backend/scripts/export_openapi.py.

**Bàn giao đầu tiên:** API đăng ký/đăng nhập và lấy tài khoản thật dùng được trên app của Sơn.
Đăng ký tạo user + CASH account + tiền giả lập trong một transaction; tiền dùng Decimal.

Mã TODO tương ứng: BE-01, BE-02, BE-03. BE-04/vnstock làm sau bản demo.
Sau CP1 còn API thị trường, chart, watchlist, assets/portfolio (chặng 2), hỗ trợ tích hợp
giao dịch (chặng 3) và phần báo cáo. Chưa có xác nhận Flutter chạy trọn luồng với backend.
Tra [API_CONTRACT](../API_CONTRACT.md), [BUSINESS_RULES](../BUSINESS_RULES.md);
cập nhật [WORK_BOARD](../WORK_BOARD.md).
