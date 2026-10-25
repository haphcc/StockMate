# Tuệ — Nghiệp vụ giao dịch

**Bắt đầu tại:** backend/app/services/order_service.py và matching_service.py.
Đọc ví dụ tiền/cổ phiếu ở [BUSINESS_RULES](../BUSINESS_RULES.md) trước khi code.

1. Cùng Phuoc chốt schema và viết test giữ/giải tỏa tiền/cổ phiếu; Phuoc giữ migration.
2. Nhận xác thực và DB session từ LB; viết kiểm tra chủ tài khoản, sức mua, số lượng và giá hợp lệ.
3. Viết đặt/khớp/hủy lệnh; tiền, cổ phiếu, lịch sử và thông báo thay đổi trong cùng transaction.
4. Viết API sổ lệnh/lịch sử/thông báo, bàn giao JSON và lỗi cho Me (TV3).
5. Viết xử lý T+2 theo từng đợt mua; chạy lại không cộng cổ phiếu lần hai.
6. Cùng Châu test gửi trùng, hai lệnh đồng thời, hủy và lỗi giữa chừng.

**File phụ trách:** backend/app/ phần orders, transactions, notifications và settlement;
backend/scripts/settle_shares.py. SQL/routine phối hợp Phuoc.

**Bàn giao đầu tiên:** luật/test và tên routine được thống nhất; sau đó API mua/bán/hủy chạy đúng tiền.
Chỉ CASH/LO trong demo; không tin số phí/thuế từ client, không che số âm bằng làm tròn/clamp.

Mã TODO tương ứng: TR-01, TR-02, TR-03.
Tra [API_CONTRACT](../API_CONTRACT.md), [DATABASE_WORKFLOW](../DATABASE_WORKFLOW.md);
cập nhật [WORK_BOARD](../WORK_BOARD.md).
