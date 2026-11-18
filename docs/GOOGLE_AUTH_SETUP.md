# Hướng Dẫn Cấu Hình & Tích Hợp Đăng Nhập / Đăng Ký Bằng Google

> **Dự án**: StockMate — Ứng dụng giao dịch chứng khoán  
> **Tính năng**: Google OAuth 2.0 Sign-In / Sign-Up (Seamless Auto-Linking, Provisioning & Admin Visibility)

---

## 1. Luồng hoạt động (Seamless UX)

1. **Một chạm duy nhất (Single Tap Flow):**
   - Nút **Google** tại màn hình **Đăng nhập** và **Đăng ký** đều gọi cùng endpoint `POST /api/auth/google`.
   - Hỗ trợ cả `id_token` (Android / iOS / Web GIS) và `access_token` (fallback cho Flutter Web).
2. **Xác minh bảo mật:**
   - Backend xác thực token với Google, kiểm tra `audience` (khi cấu hình `GOOGLE_CLIENT_ID`) và bắt buộc `email_verified == True`.
3. **Tự động liên kết tài khoản (Auto-Link):**
   - Nếu `google_id` hoặc `email` đã tồn tại trong CSDL: đăng nhập ngay, đánh dấu `auth_provider = 'GOOGLE'`, liên kết `google_id` và cập nhật `avatar_url` nếu chưa có.
4. **Tự động tạo mới & cấp vốn trải nghiệm (Auto-Provisioning):**
   - Nếu là người dùng mới: tạo atomically trong 1 transaction gồm bản ghi `customers` (`auth_provider = 'GOOGLE'`, `google_id = sub`, `status = 'ACTIVE'`) và 1 tài khoản đầu tư tiền mặt (`CASH`) kèm số dư khởi đầu.
   - Tài khoản Google chưa có mật khẩu riêng (`has_password = false`) có thể dùng chức năng **Đặt mật khẩu** trong *Cài đặt & Tài khoản* mà không cần mật khẩu cũ; có thể sửa tên mà không bị bắt nhập SĐT ngay.
5. **Hiển thị trong Admin Portal:**
   - API Admin (`GET /api/admin/customers`, `GET /api/admin/customers/{id}`) trả về `auth_provider` (`LOCAL` / `GOOGLE`) và `google_id`, hỗ trợ lọc `?auth_provider=GOOGLE`.
   - Giao diện Admin hiển thị badge **Google** trên danh sách khách hàng, chip lọc nguồn đăng nhập, và mục **Đăng nhập: Tài khoản Google** trong trang chi tiết khách hàng.

---

## 2. Cấu hình Google OAuth 2.0

### 2.1. Backend (`backend/.env`)

Điền **OAuth 2.0 Web Client ID** (có thể nhập nhiều Client ID cách nhau bởi dấu phẩy):

```env
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

### 2.2. Mobile App (Flutter)

- **Web (`mobile/web/index.html`):**
  Cập nhật thẻ meta trong `<head>`:
  ```html
  <meta name="google-signin-client_id" content="your-web-client-id.apps.googleusercontent.com">
  ```
- **Android (`vn.stockmate.stockmate`):**
  1. Trong Google Cloud Console (cùng project với Web Client ID), tạo **Android OAuth 2.0 Client ID** với package name `vn.stockmate.stockmate` và mã SHA-1 debug/release keystore của bạn.
  2. Chạy app kèm Web Client ID (nếu dùng project khác mặc định):
     ```bash
     flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
     ```
  3. Không commit `google-services.json` hoặc `GoogleService-Info.plist` vào git (đã được thêm vào `.gitignore`).
- **iOS (`mobile/ios/Runner/Info.plist`):**
  Thêm `CFBundleURLTypes` với `REVERSED_CLIENT_ID` của iOS OAuth Client.

---

## 3. Chạy kiểm thử & Migration

```bash
cd backend
python -m alembic upgrade head
python -m pytest -q --tb=short
python scripts/export_openapi.py --check
```
