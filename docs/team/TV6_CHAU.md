# TV6 — Châu: QA, tích hợp và bằng chứng demo

Tra file: `python scripts/check_preparation.py --owner TV6`.
Châu xác nhận bằng kết quả chạy thực tế; người giữ feature sửa lỗi trong source tương ứng.

## QA-01 — Kiểm tra nền, bắt đầu ngay

1. Theo SETUP từ checkout mới; ghi phiên bản Docker/Python/Flutter/SDK, host/port và lỗi gặp.
2. Chạy unit/contract tests backend, OpenAPI --check và check_preparation.
3. Kiểm tra fixtures khớp schema; đăng ký/order có đủ trường, money string, portfolio phẳng.
4. Xác nhận endpoint nghiệp vụ trả 501 ở scaffold và private route thiếu token trả 401.
5. Phuoc chạy migrate/seed DB mới; Châu lưu evidence QA-ENV-01/02/03.
6. Điền trạng thái WORK_BOARD thực tế; đọc hướng dẫn từng người để phát hiện dependency bị bỏ sót.

**File:** tests/unit/test_contract.py, tests/unit/test_http_contract.py, docs/qa/environment.md,
docs/WORK_BOARD.md, docs/ACCEPTANCE_TESTS.md, scripts/check_preparation.py.

## QA-02 — G1 và G2, sau LB/Sơn/Me bàn giao

1. Chuẩn bị hai user và ít nhất hai account của cùng user để test ID và cache.
2. Viết integration test DB riêng cho ownership; không dùng DB cá nhân hoặc shared DB có dữ liệu thật.
3. Flutter integration: register → login → me → chọn CASH → board → detail → portfolio.
4. Test token hết hạn/refresh lỗi, app restart/logout, không để UI hiện tài khoản user trước.
5. Test error/loading/empty/network off; không xác nhận pass từ screenshot UI tĩnh.
6. Mỗi bug có: steps, payload redacted, expected, actual, commit, device, người sửa và retest.

**File:** backend/tests/integration/test_auth_accounts.py (tạo khi BE-01 có code),
backend/tests/integration/test_market.py; mobile/integration_test/auth_market_test.dart;
docs/qa/*.md. Báo Sơn/Me sửa implementation thay vì Châu sửa chồng mọi file.

**Xong khi:** QA-AUTH/OWN/MKT/ACC case liên quan pass và có log/ảnh của luồng API thật.

## QA-03 — Giao dịch và demo, sau TR-02/03

1. Test theo bảng ACCEPTANCE_TESTS, ưu tiên tiền/khóa/duplicate/T+2.
2. Dùng PostgreSQL thật, hai connection độc lập cho cạnh tranh; không giả lập SQLite.
3. Đọc balance/portfolio/order/transactions trước/sau; đối chiếu bất biến và công thức đúng 0.01 đồng.
4. Test mobile retry giữ client_order_id, cancel cập nhật cả order và tài sản, 501 không báo thành công.
5. Chuẩn bị demo theo thứ tự: login → xem giá → mua pending → hủy → mua khớp → xem holdings/history.
6. Ghi cách đổi giá và chạy T+2 bằng tool DEV do Phuoc/Tuệ cung cấp, không phụ thuộc giờ sàn thật.
7. Chạy trên emulator và Android máy thật; lưu APK commit SHA và test result vào docs/qa/demo.md.
8. Tổng hợp báo cáo/UML và ảnh chụp từ bản thật; đánh dấu tính năng để sau đúng MVP_SCOPE.

**File:** backend/tests/integration/test_trading.py; mobile/integration_test/trading_test.dart;
docs/qa/demo.md, docs/qa/bugs.md, tài liệu báo cáo riêng khi nhóm bắt đầu viết.

## Mẫu báo lỗi

```text
Bug: BUG-001, liên quan QA-ORD-06
Commit/device/schema revision: ...
Steps + payload (không có token): ...
Expected: một lệnh, một reserve
Actual: ...
Người xử lý: Tuệ
Retest: NOT RUN / PASS / FAIL, bằng chứng ...
```

**PR đầu tiên:** `codex/QA-01-setup-contract-evidence`.
**Chưa có code thì ghi:** NOT RUN, đang chờ task ID nào. Không tự đánh dấu pass/xfail cả luồng.
