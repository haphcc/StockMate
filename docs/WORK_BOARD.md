# Bảng tiến độ

Châu cập nhật khi người nhận đã thử bàn giao. Chọn một trạng thái:
**Chưa làm / Đang làm / Chờ bàn giao / Xong**. Nếu bị chặn, ghi rõ cần ai hỗ trợ ở cột ghi chú.

| Người | Việc ở chặng 1 | Trạng thái | Ghi chú/cần ai |
|---|---|---|---|
| Phuoc | Dựng DB, migration, seed và môi trường | Chưa làm | Bàn giao kết nối/cách dựng cho LB, Tuệ, Châu |
| Sơn | Form auth, token và nối API đăng nhập | Chưa làm | Dùng JSON mẫu trước; nối API khi LB bàn giao |
| Me (TV3) | Bảng giá/chi tiết với JSON mẫu | Chưa làm | Nhận helper/network/router từ Sơn |
| LB | FastAPI, kết nối DB, health, auth và accounts | Chờ bàn giao | CP1 backend đã kiểm thử PostgreSQL thật; xem [TV4_CP1](qa/TV4_CP1.md). Sơn/Châu cần xác nhận luồng trên Flutter; chưa đánh dấu Xong |
| Tuệ | Chốt luật và test giữ tiền/cổ phiếu cùng Phuoc | Chưa làm | Chuẩn bị trước khi viết API giao dịch |
| Châu | Thử setup, soạn case và kiểm tra auth khi có API | Chưa làm | Ghi phần chưa chạy thay vì đánh dấu pass |

| Chặng | Xong khi | Trạng thái |
|---|---|---|
| 1 — Nền và đăng nhập | Dựng lại được môi trường; app đăng ký/đăng nhập lấy tài khoản thật | Chưa xong |
| 2 — Thị trường và tài sản | Bảng giá, chi tiết/chart, watchlist, tài sản/danh mục nối API; nạp tiền payOS VietQR (Phuoc + Sơn); phân hệ Quản trị Admin: API CRUD toàn diện tất cả các bảng gồm xóa khách hàng, đổi status (Phuoc) & Tab Quản trị ẩn mobile (Châu) | Chưa xong |
| 3 — Giao dịch và demo | Mua/bán/hủy, T+2 đúng; test trọn luồng và APK demo | Chưa xong |

Qua mỗi chặng, thay cột việc trong bảng đầu theo [PLAN](PLAN.md), không tạo thêm bảng sprint.
Chưa ấn định deadline; Phuoc điền ngày đã thống nhất với nhóm vào ghi chú.

Chỉ ghi **Xong** khi có code, đã chạy thử, người nhận dùng được và có commit/PR hoặc kết quả test.
Khung và tài liệu đã chuẩn bị; các tính năng chưa được coi là hoàn thành.
Chi tiết test ở [ACCEPTANCE_TESTS](ACCEPTANCE_TESTS.md); kết quả thực tế lưu trong [qa](qa/README.md).
