# TV2 — Sơn: Flutter nền, auth, dashboard và danh mục

Tra file: `python scripts/check_preparation.py --owner TV2` từ repo gốc.
Đọc API_CONTRACT và JSON mẫu trước khi sửa model. Mở `mobile/` làm Flutter project.

## FE-01 — Sửa model và form bằng fixture, bắt đầu ngay

**Input:** docs/contracts/examples.json. Không chờ API thật.

1. Làm `core/utils/money.dart`: tiền từ string, giữ chính xác đến 0.01 đồng bằng Decimal hoặc BigInt cents.
   Chọn một biểu diễn dùng xuyên model; không qua double. Nếu thêm package, cập nhật pubspec và lock cùng PR.
2. Sửa AccountModel/UserModel/PortfolioModel; portfolio phẳng, thêm cash blocked và qty blocked/pending.
3. Phối hợp Me sửa StockModel theo cùng helper tiền. MarketRepository hiện do Sơn giữ để tránh đụng file.
4. Register form gửi đủ full_name/email/phone_number/password; kiểm tra confirm ở client.
   Tách email/SĐT thành hai trường; bỏ default contact giả và gọi Form.validate() trước submit.
5. Login chỉ email/password; bỏ tự điền credential rỗng. Ẩn Google/Apple/sinh trắc học/OTP/quên password chưa làm.
6. Thêm unit test model từ fixture, string có phần lẻ và số lớn; widget test form.
7. Sửa widget_test để mock secure storage/font/network có kiểm soát; test vẫn kiểm tra app thật khởi tạo.

**File chính:** core/utils/money.dart; data/models/{user,account,portfolio}_model.dart;
features/auth/screens/*.dart; test/unit/money_test.dart; test/widget_test.dart; pubspec.yaml/lock.

**Xong khi:** JSON mẫu deserialize đúng, không mất .01; form thiếu password không gửi request;
`flutter analyze` và test xanh. Chụp màn hình form đúng contract để LB/Châu đối chiếu.

## FE-02 — API auth và quản lý account, sau BE-01/02

1. Viết token_storage lưu access/refresh riêng; clear cả hai khi phiên hỏng/logout.
2. Dio thêm Authorization, parse error envelope; chỉ refresh một lần và chia sẻ request refresh đang chạy.
   Không refresh chính route login/refresh, không retry vòng lặp; không log token/password.
3. Implement API auth/market datasource và ApiAuthRepository/ApiMarketRepository.
   `AuthRepository` trả UserModel cho caller; token được repository lưu/khôi phục theo TokenResponse.
4. Sửa provider chọn repository theo USE_MOCK; false phải gọi API thật, không fallback mock.
5. Thêm selected_account_provider: gọi GET accounts, chọn CASH ACTIVE của user, truyền account_id
   vào assets/portfolio. `getAccountSummary(userId)` cũ phải đổi cùng caller thành account_id rõ nghĩa.
6. Update AuthNotifier dùng token thật, không còn mock_token_123 ở đường API.
7. Giữ GoRouter ổn định qua auth refresh, dispose router khi phù hợp; test restart/logout/401.
8. Cấu hình Android cleartext chỉ debug và URL theo môi trường; phối hợp Phuoc khi build APK.

**File chính:** core/network/*, core/storage/token_storage.dart, core/config/app_config.dart,
core/router/app_router.dart, providers/*.dart, data/datasources/{auth,market}_datasource.dart,
data/repositories/{auth,market,api_auth,api_market,mock_auth,mock_market}_repository.dart,
features/auth/providers/auth_provider.dart, Android debug manifest, iOS Info.plist.

**Xong khi:** BE login → lưu token → me → chọn CASH account → đọc board thật trên emulator;
khởi động lại khôi phục phiên, logout xóa cache, 401 chỉ refresh một lần. Châu xác nhận G1.

## FE-04 — Dashboard và portfolio sau BE-03

1. Dashboard đọc data thật, bỏ số dư/chỉ số/tin tức/table viết cứng; ẩn phần chưa có nguồn.
2. Nhận widget/table từ Me hoặc route sang MarketBoard; tránh dựng hai bộ bảng giá khác nhau.
3. PortfolioScreen dùng provider theo account, đủ available/blocked/pending, giá vốn và P/L.
4. Đổi account/user phải đổi khóa provider và xóa state cũ; không hiển thị tài khoản người trước.
5. Thống nhất callback/invalidation với Me sau place/cancel; kiểm tra tài sản đổi theo giá demo.
6. Đủ loading/empty/error, retry và nguồn DEMO; giữ theme/widget dùng chung.

**File chính:** features/home/*, features/portfolio/*, providers/selected_account_provider.dart.
**Xong khi:** QA-ACC-01, QA-MKT-04, QA-UI-01 pass.

**PR đầu tiên:** `codex/FE-01-models-auth-form`.
**Bàn giao cho Me:** helper tiền, router/network conventions, selected account và provider invalidation.
**Khi cần sửa file Me giữ:** báo rõ method/field cần thêm trong PR; không tự copy model/utility thứ hai.
