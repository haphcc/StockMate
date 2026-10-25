# Luật nghiệp vụ MVP — dùng khi viết code và test

Chủ trì: TV1 + TV5. Luật này là đích triển khai; SQL baseline hiện chưa đáp ứng đủ.
Số tiền VND dùng Decimal chính xác, làm tròn HALF_UP đến 0.01 đồng ở mỗi khoản phí/thuế.
Timestamp lưu UTC có offset; ngày thanh toán dựa trên Asia/Ho_Chi_Minh.

## AUTH-01: đăng ký và quyền truy cập

- Email chuẩn hóa trim/lowercase; SĐT chuẩn 10 số `0[35789]xxxxxxxx`.
- Bắt buộc email, SĐT, họ tên, password; email và SĐT duy nhất; không tự điền email/SĐT giả.
- Password 8–72 ký tự; khi dùng bcrypt kiểm tra thêm tối đa 72 byte UTF-8, không cắt ngầm.
- Một transaction DB tạo customer ACTIVE + CASH account ACTIVE + 1,000,000,000.00 tiền giả lập.
- Tài khoản sinh số duy nhất ở server; trùng cạnh tranh phải retry có giới hạn trong transaction mới.
- Không cấp tiền lại khi login/refresh. Đăng ký trùng trả 409.
- Mọi truy vấn account/order/transaction/notification đều giới hạn theo customer của JWT.
- ID của khách hàng khác trả 404; customer LOCKED/CLOSED và account SUSPENDED/CLOSED không được giao dịch.
- Login chỉ bằng email/password; sai thông tin trả 401 chung, không tiết lộ email tồn tại hay không.
- Access JWT 15 phút, refresh JWT 14 ngày; claim `sub`, `type`, `exp`, `iat`; phân biệt access/refresh.
- MVP chưa rotate/revoke refresh token; logout xóa cả hai token ở thiết bị. Không quảng bá logout là thu hồi server.

## ORD-01: đặt lệnh

- Chỉ CASH + LO; stock/customer/account phải ACTIVE.
- `client_order_id` UUID do mobile tạo cho mỗi ý định đặt lệnh. Retry giữ nguyên UUID.
- Duy nhất `(account_id, client_order_id)`. Cùng UUID và payload trả lệnh đã có (201);
  cùng UUID khác payload trả 409 `IDEMPOTENCY_CONFLICT`. Không phong tỏa/giao dịch lần hai.
- Quantity là số nguyên dương, bội số 100 cho cả ba sàn trong MVP.
- `floor_price <= order_price <= ceiling_price`, giá > 0 và đúng bước giá tại chính giá đặt.
- HOSE: <10,000 → 10; <50,000 → 50; còn lại 100 đồng. HNX/UPCOM: 100 đồng.
- Giá trần/sàn tính theo bước giá tại vùng giá kết quả; test cả khi vượt ngưỡng 10,000/50,000.
- Không dùng giá client gửi làm giá thị trường; khóa/đọc bản ghi stock trong transaction server.

## CASH-01: phong tỏa, khớp và hủy BUY

Đặt `fee(x) = round(x * 0.0015, 2, HALF_UP)`.

- Reserve = `quantity * limit_price + fee(quantity * limit_price)`.
- Thiếu `cash_balance` khả dụng → 409 `INSUFFICIENT_CASH`, không tạo lệnh/phong tỏa nửa chừng.
- Đặt thành công: `cash -= reserve`, `blocked += reserve`; NAV không đổi do việc phong tỏa.
- BUY khớp khi `current_price <= limit_price`, tại `current_price`, toàn bộ khối lượng.
- Gross = qty × giá khớp; actual = gross + fee(gross).
- Khớp: `blocked -= reserve`, `cash += reserve - actual`; không trừ actual thêm lần nữa vào cash.
- Cổ phiếu tăng quantity, chưa tăng available cho phần chưa đến T+2; tính lại average_price và NAV.
- Hủy PENDING: `blocked -= reserve`, `cash += reserve`; không sinh transaction giao dịch.

Ví dụ phải dùng làm test:

| Bước | Cash | Blocked | Quantity mới |
|---|---:|---:|---:|
| Ban đầu | 1000000000.00 | 0.00 | 0 |
| BUY 100 × 100000, fee 15000 | 989985000.00 | 10015000.00 | 0 |
| Khớp ở 99000, gross 9900000, fee 14850 | 990085150.00 | 0.00 | 100 |

Nếu hủy thay vì khớp: cash trở lại 1000000000.00, blocked 0, không có cổ phiếu mới.

## SHARE-01: phong tỏa, khớp và hủy SELL

- Đích schema: `quantity = available_quantity + blocked_quantity + pending_quantity`.
- Quantity sở hữu gồm cả phần chờ về và đang giữ cho lệnh bán; các phần đều không âm.
- Đặt SELL: available giảm, blocked_quantity tăng cùng lượng. Thiếu available trả 409.
- SELL khớp khi `current_price >= limit_price`, tại current_price, toàn bộ khối lượng.
- Thuế = round(gross × 0.001, 2, HALF_UP); net = gross - fee - tax.
- Khi khớp: quantity và blocked_quantity cùng giảm; cash tăng net ngay (giản lược MVP).
- Khi hủy: blocked_quantity giảm, available tăng; quantity và cash không đổi.
- Chỉ xóa dòng portfolio khi quantity = available = blocked = pending = 0.
- Giá vốn còn lại không đổi khi bán; nếu mua thêm: `(qty_cũ * avg_cũ + qty_mới * giá_khớp) / tổng_qty`.

Ví dụ SELL 100 × 100000: gross 10000000.00, fee 15000.00, tax 10000.00, net 9975000.00.

## STATE-01: chuyển trạng thái và đồng thời

- MVP tạo PENDING → COMPLETED hoặc CANCELLED. PARTIAL/REJECTED chỉ đọc từ lịch sử seed.
- Validation thất bại trả lỗi, không tạo REJECTED tự động. Lệnh terminal không được khớp thêm.
- Cancel lại CANCELLED trả cùng lệnh 200; cancel COMPLETED trả 409 `ORDER_NOT_CANCELLABLE`.
- Khóa theo thứ tự thống nhất: account → stock → portfolio → order; không đảo thứ tự ở worker.
- Một transaction bao gồm validation sau khóa, reserve/release, ghi order/transaction/notification và NAV.
- Engine có khóa và ràng buộc chống duplicate fill; gọi worker lần hai không khớp lại.
- Không dùng `LEAST`/`GREATEST` để che việc khớp quá lượng hoặc bán quá số dư.
- Chỉ backend/worker nội bộ được ghi transactions; client không được submit fee/tax/net_amount.

## SETTLE-01: T+2 theo từng đợt

- T là ngày giao dịch theo Asia/Ho_Chi_Minh; cộng 2 ngày thứ Hai–thứ Sáu, bỏ cuối tuần.
- Ví dụ thứ Sáu 23/10/2026 → thứ Ba 27/10/2026. Chưa xử lý ngày lễ trong demo.
- Có ledger theo từng giao dịch mua: quantity, settlement_date, trạng thái đã thanh toán.
- Job nhận `as_of_date` để kiểm thử; mỗi đợt đến hạn chỉ giải phóng đúng lượng của đợt đó một lần.
- Mua 100 về hôm nay và 200 về ngày mai: hôm nay available +100, không phải +0 hoặc +300.
- Chạy lại cùng ngày không đổi lần hai; không giải phóng cổ phiếu đang giữ cho SELL.

## MKT-01: giá và cập nhật UI

- DB `stocks.current_price` là nguồn giá duy nhất; data_source DEMO/LIVE phải hiển thị đúng.
- Chế độ DEMO đọc seed/đổi giá bằng công cụ DEV; is_stale=true để không giả mạo dữ liệu trực tiếp.
- LIVE chỉ bổ sung sau: is_stale khi quá 30 giây không có quote trong phiên; không khớp theo quote stale.
- Sau đổi giá: định giá lại portfolio/NAV, sau đó engine xét PENDING trong transaction riêng có khóa.
- Mobile polling 10 giây khi màn hình đang hoạt động; dừng khi nền, hủy provider khi rời màn hình.
- Sau đặt/hủy: invalidate order, transaction, asset, portfolio, notification của account tương ứng.
- Màu giá lấy price_state; màu tham chiếu vàng, trần tím, sàn xanh lơ, tăng xanh, giảm đỏ.

## Ai thực hiện ở đâu

| Việc | Chỗ thực hiện | Chủ |
|---|---|---|
| Kiểm tra request/JWT/ownership, mở transaction và lấy khóa | backend endpoints + services | LB/Tuệ |
| Chọn lệnh đủ điều kiện, tạo fill duy nhất | `services/matching_service.py` | Tuệ |
| Tính phí/thuế/net, apply fill, reserve/release, settlement | SQL function/procedure trong migration nhóm tự viết | Phuoc + Tuệ |
| Serialize Decimal thành string và dựng response | schemas + endpoint mapping | LB/Tuệ |
| Hiển thị và ước tính trước lệnh, không quyết định số dư thật | Flutter providers/widgets | Sơn/Me (TV3) |

TR-01 phải tạo migration/routine theo luật trên; baseline 0001 chưa phải engine đạt chuẩn.
