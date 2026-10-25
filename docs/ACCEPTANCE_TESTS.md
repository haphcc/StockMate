# Kịch bản nghiệm thu — Châu quản lý

Không đánh dấu pass từ tài liệu. Ghi task/commit, môi trường, ngày chạy, expected/actual và bằng chứng
ở `docs/qa/`; dữ liệu tài khoản demo, không đưa token/password thật vào log.

| ID | Mốc | Thực hiện | Expected | Người sửa |
|---|---|---|---|---|
| QA-ENV-01 | Chặng 1 | Migrate DB trống, seed | 9 bảng app, 6 view, 83 stocks, 10 customers, 13 accounts | Phuoc |
| QA-ENV-02 | Chặng 1 | Migrate lần hai, seed lần hai | Migrate no-op; seed từ chối, dữ liệu giữ nguyên | Phuoc |
| QA-ENV-03 | Chặng 1 | DB tắt hoặc URL sai | live 200; ready 503, không lộ credentials | LB |
| QA-AUTH-01 | Chặng 1 | Register đủ 4 trường | 201, customer + CASH account + đúng 1 tỷ, token hợp lệ | LB/Sơn |
| QA-AUTH-02 | Chặng 1 | Thiếu password/email/SĐT, password confirm sai ở UI | 422/server, lỗi form/client; không tạo user | LB/Sơn |
| QA-AUTH-03 | Chặng 1 | Email/SĐT trùng, kể cả hai request cùng lúc | 409; không tạo account/cấp tiền một nửa | LB |
| QA-AUTH-04 | Chặng 1 | Login sai password hoặc email không tồn tại | 401 chung, không token | LB |
| QA-AUTH-05 | Chặng 1 | Access hết hạn; hai request đồng thời | Một refresh chia sẻ, retry tối đa một lần/request | LB/Sơn |
| QA-AUTH-06 | Chặng 1 | Refresh sai/hết hạn, restart app, logout | Xóa phiên khi lỗi; khôi phục phiên hợp lệ; logout local rõ ràng | LB/Sơn |
| QA-AUTH-07 | Chặng 1 | Dùng refresh token làm access và ngược lại | Bị từ chối theo type claim | LB |
| QA-OWN-01 | Chặng 1–3 | User A gọi assets/portfolio/orders/transactions/cancel của B | 404, không thấy hoặc đổi dữ liệu B | LB/Tuệ |
| QA-MKT-01 | Chặng 2 | Filter HOSE/HNX/UPCOM, tìm mã/tên, paginate | Đúng danh sách và envelope, sort ổn định | LB/Me (TV3) |
| QA-MKT-02 | Chặng 2 | Chart 1M/3M/6M, watchlist add/delete lặp | Đúng date ASC; không trùng watchlist | LB/Me (TV3) |
| QA-MKT-03 | Chặng 2 | Price_state đủ 5 trạng thái | Đúng tím/xanh lơ/vàng/xanh lá/đỏ | Me (TV3) |
| QA-MKT-04 | Chặng 2 | Đổi giá DEV một mã đang giữ | Board và NAV đúng sau refresh, vẫn ghi nguồn DEMO | Phuoc/LB/Sơn |
| QA-ACC-01 | Chặng 2 | Chọn hai account, logout/login user khác | Không lẫn cache; request dùng account_id đúng | Sơn |
| QA-ORD-01 | Chặng 3 | BUY ví dụ CASH-01 | Cash/blocked/gross/fee/holdings đúng từng bước | Tuệ |
| QA-ORD-02 | Chặng 3 | Cancel BUY pending, cancel lại | Trả tiền đúng một lần, không sinh fill | Tuệ |
| QA-ORD-03 | Chặng 3 | SELL ví dụ SHARE-01, cancel SELL khác | Phí/thuế/net đúng; giải tỏa cổ phiếu đúng | Tuệ |
| QA-ORD-04 | Chặng 3 | Thiếu cash/available, account khóa, MARGIN, MP, sai tick/band/lot | Lỗi phù hợp; không tác động dở dang | Tuệ |
| QA-ORD-05 | Chặng 3 | Giá chưa đủ điều kiện, rồi thay giá DEV | PENDING → COMPLETED đúng giá server một lần | Tuệ |
| QA-ORD-06 | Chặng 3 | Retry cùng UUID và payload; cùng UUID payload khác | Không duplicate; khác payload trả 409 | Tuệ |
| QA-ORD-07 | Chặng 3 | Hai BUY cạnh tranh cùng cash; hai SELL cùng cổ phiếu | Không âm và không phong tỏa quá lượng | Tuệ/Phuoc |
| QA-ORD-08 | Chặng 3 | Worker khớp đồng thời cancel; chạy worker lại | Chỉ một trạng thái terminal, không double fill/release | Tuệ |
| QA-ORD-09 | Chặng 3 | Giả lập lỗi ở giữa transaction | Rollback cả order/fill/balance/portfolio/notification | Tuệ |
| QA-SET-01 | Chặng 3 | Mua thứ Sáu 23/10/2026 | Settlement 27/10/2026 theo lịch mô phỏng | Tuệ |
| QA-SET-02 | Chặng 3 | Hai đợt 100/200 về khác ngày; chạy lại job | Giải phóng đúng 100 rồi 200, không lặp | Tuệ |
| QA-SET-03 | Chặng 3 | Settlement khi có SELL đang giữ cổ phiếu khác | Không giải phóng phần blocked SELL | Tuệ |
| QA-UI-01 | Chặng 2–3 | Loading/empty/error/timeout/501/network off | Không hiện thành công giả; retry cùng UUID | Sơn/Me (TV3) |
| QA-NOT-01 | Chặng 3 | Đặt/khớp/hủy, mark-read hai lần, user khác | Notification đúng chủ, không lặp do retry | Tuệ/Me (TV3) |
| QA-DEMO-01 | Chặng 3 | Chạy kịch bản ngoài giờ, mất internet, APK máy thật | Demo dùng seed; không phụ thuộc nguồn live | Phuoc/Châu |

## Tự động hóa trước

- Backend unit: money contract, validation, token, công thức giao dịch, lịch T+2.
- Backend integration PostgreSQL thật: khóa, unique key, trigger, rollback, settlement; không thay bằng SQLite.
- Flutter unit: model tiền string, map portfolio phẳng, request register/order.
- Flutter widget/integration: login → account → board; place/cancel cập nhật provider đúng.
- Đầu việc DB/trading chưa có code thì ghi NOT RUN/BLOCKED theo task; không `xfail` cả nhóm test để tạo xanh giả.

## Mẫu ghi bằng chứng

```text
Case: QA-ORD-01
Commit: <sha>
Môi trường: local/Docker, schema revision ...
Ngày chạy: ...
Dữ liệu đầu vào: ...
Expected: ...
Actual: ...
Trạng thái: PASS / FAIL / NOT RUN
Log/ảnh: ...
Bug liên quan và người xử lý: ...
```
