# TV4 — LB: backend nền, auth, tài khoản và thị trường

Tra file: `python scripts/check_preparation.py --owner TV4`. Làm trong `backend/`.
Các file hiện chỉ có TODO. LB tự viết app, config, schema, routes, errors, health và DB session.

## BE-01 — Auth thật và đăng ký atomic

**Input:** ENV-01 của Phuoc; API_CONTRACT + AUTH-01; không chờ toàn bộ trading migration.

1. Viết app/main.py, Settings, errors, health, DB session/Base, router và request/response schemas theo API_CONTRACT.
   Map Customer/InvestmentAccount đúng tên/cột/Decimal; không dùng create_all thay migration.
2. Điền core/security.py: bcrypt verify/hash, byte limit, JWT access/refresh phân biệt type.
3. Đọc SECRET_KEY/TTL từ Settings; fail cấu hình auth thiếu/placeholder; không dùng khóa demo hardcode.
4. Viết CRUD auth/accounts không commit; AuthService mở transaction tạo customer + CASH account
   + cấp tiền giả lập một lần. Account number unique, xử lý race bằng constraint/retry đúng transaction.
5. Register/login/refresh trả TokenResponse theo schema; login sai trả 401 chung, trùng email/SĐT 409.
6. Tự viết `require_user`: verify token + lấy customer; chặn token sai type/hết hạn và user bị khóa.
7. GET me trả user hiện tại; logout MVP là clear local. Không thêm API thu hồi token chưa có lưu trữ.
8. Viết unit/integration test; tự viết exporter và sinh OpenAPI khi app/schema đã có. Bổ sung CI cùng Phuoc/Châu.

**File:** app/core/{config,security,errors}.py; app/db/{base,session}.py;
app/models/{customer,investment_account}.py; app/crud/{auth,accounts}.py;
app/services/auth_service.py; app/api/deps.py; app/api/v1/endpoints/auth.py;
tests/unit/test_auth.py (tạo khi viết tính năng); integration phối hợp Châu.

**Xong khi:** QA-AUTH-01–07, seed login được; Sơn gọi app thật không phải mock token.

## BE-02 — Account + board, giao sớm để đạt G1

1. GET accounts filter customer_id từ JWT, sắp ID; chọn account theo account_id riêng.
2. Map stocks/portfolio; assets theo v_account_summary, portfolio phẳng có Decimal strings.
   Trước migration blocked_quantity, không bịa quantity; chỉ bật field đích sau TR-01 hoặc đánh dấu phần chờ.
3. Board filter exchange + q, paginate/sort như contract; không trả toàn DB cho client tự lọc.
4. DEMO metadata thật; is_stale=true với seed, bỏ nhãn LIVE sai nghĩa.
5. Tài khoản khác chủ trả 404; CASH/MARGIN đọc được, trading chỉ CASH do Tuệ kiểm tra.
6. Test 401/404, nhiều account, money JSON, page query, quote metadata.

**File:** app/models/{stock,portfolio}.py; app/crud/{accounts,market}.py;
app/services/{account,market}_service.py; endpoints/{accounts,market}.py.
**Xong khi:** QA-OWN-01 (phần read), QA-MKT-01, Sơn/Me (TV3) đạt G1.

## BE-03 — Chart, portfolio hoàn chỉnh và watchlist sau TR-01

1. Map stock_price_history/watchlist, cập nhật portfolio theo migration đích.
2. Chart lấy 22/66/132 phiên mới nhất rồi trả tăng dần; unknown symbol 404.
3. Assets/portfolio đúng available/blocked/pending và NAV; zero denominator trả null.
4. Watchlist một list mặc định, GET/POST/DELETE idempotent; ràng buộc unique chống race.
5. Test add/delete lặp, không lộ watchlist người khác, đổi giá định giá lại đúng.

**File:** app/models/{stock_price_history,watchlist,portfolio}.py; crud/watchlist.py;
endpoints/{market,accounts,watchlist}.py; services tương ứng.
**Xong khi:** G2 và QA-MKT-02/04 pass.

## BE-04 — Live feed là mở rộng sau G4

`scripts/sync_market_data.py` mới là placeholder. Chỉ triển khai sau demo seed ổn định:
chọn nguồn/version vnstock đã kiểm chứng, timeout/retry, unit normalization về VND,
backoff/rate limit, lịch phiên, cập nhật reference/volume/OHLCV và quote freshness.
Không cài vnstock rồi mặc định tuyên bố đã có feed real-time.

**PR đầu tiên:** `codex/BE-01-auth`.
**Bàn giao cho Sơn:** URL, login/register/refresh JSON + mã lỗi; cho Tuệ: dependency current_user và Session;
cho Châu: dữ liệu 2 user để test ownership. Không gửi token thật vào tài liệu.
