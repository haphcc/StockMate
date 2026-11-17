# Hướng Dẫn Cấu Hình & Kết Quả Tích Hợp Đăng Nhập / Đăng Ký Bằng Google

> **Dự án**: StockMate — Ứng dụng giao dịch chứng khoán  
> **Tính năng**: Google OAuth 2.0 Sign-In / Sign-Up (Seamless Auto-Linking & Provisioning)  
> **Thời gian hoàn thành**: 17/11/2026  

---

## 1. Đề Xuất Trải Nghiệm Mượt Mà (Seamless UX - Đã triển khai)

Để người dùng **không gặp bất kỳ lỗi xung đột nào** giữa đăng ký thường và Google:

1. **Một chạm duy nhất (Single Tap Flow)**:
   - Dù người dùng bấm nút **Google** tại màn hình **Đăng nhập** hay **Đăng ký**, luồng xử lý đều thống nhất và tự động nhận diện.
2. **Tự động liên kết tài khoản (Auto-Link / Merge Account)**:
   - Nếu email tài khoản Google **đã tồn tại** trong cơ sở dữ liệu (đã từng tạo bằng email/mật khẩu): hệ thống **tự động xác thực thành công** và cấp token đăng nhập ngay lập tức (không bắt nhập mật khẩu cũ, không báo lỗi "Email đã tồn tại").
   - Tự động cập nhật thêm `avatar_url` từ ảnh đại diện Google nếu tài khoản chưa có avatar.
3. **Tự động tạo mới & cấp vốn trải nghiệm (Auto-Provisioning)**:
   - Nếu email **chưa từng tồn tại**: hệ thống tự động tạo hồ sơ khách hàng mới, gán số điện thoại định danh an toàn `G<google_sub_id>`, cấp `status="ACTIVE"`.
   - Tự động khởi tạo ngay **Tài khoản đầu tư tiền mặt (CASH Account)** với số dư khởi đầu (100.000đ khi chạy thực tế hoặc 1.000.000.000đ khi chạy test).
4. **Bảo mật**:
   - Trường mật khẩu được lưu giá trị bảo vệ `GOOGLE_OAUTH_ACCOUNT` (không thể bị brute-force qua form mật khẩu thông thường). Người dùng muốn đặt mật khẩu riêng có thể dùng chức năng Đổi mật khẩu trong hồ sơ cá nhân.

---

## 2. Hướng Dẫn Chi Tiết: Đặt Credentials API Vào Đâu?

Bạn đã có sẵn Google Cloud Project / OAuth credentials, dưới đây là vị trí chính xác để điền vào dự án:

### Bước 2.1: Cấu hình Backend (Web Client ID)

Backend sử dụng thư viện `google-auth` để xác thực `id_token` do Google cấp.

1. Mở file [backend/.env](file:///d:/Vscode/StockMate/backend/.env)
2. Điền **OAuth 2.0 Web Client ID** vào dòng:
   ```env
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```
   *(Ví dụ: `1234567890-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com`)*

---

### Bước 2.2: Cấu hình Ứng Dụng Android

1. **Package Name (Application ID)** của app là:  
   `vn.stockmate.stockmate`
2. **Mã vân tay chứng chỉ Debug (SHA-1 & SHA-256)** trên máy của bạn:
   - **SHA-1**: `6B:ED:79:D9:E1:EB:B1:E8:A6:2B:2E:28:28:63:15:A4:5F:F5:2F:D3`
   - **SHA-256**: `5A:85:67:53:64:79:8D:73:B5:9B:9F:56:0A:74:BE:AD:55:99:B0:49:2F:9C:FB:CC:CA:92:E8:5D:28:31:FE:A1`
   *(Lưu ý: Không dùng `./gradlew` vì thư mục `mobile/android` không có sẵn file wrapper `gradlew.bat`. Bạn có thể kiểm tra lại bất cứ lúc nào bằng lệnh: `keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android`)*
3. Trong **Google Cloud Console** / **Firebase Console**:
   - Thêm app Android với package name: `vn.stockmate.stockmate`
   - Dán mã **SHA-1** ở trên vào ô **Certificate fingerprint**.
   - Tải file **`google-services.json`**.
4. **Vị trí đặt file**:
   - Copy file `google-services.json` vào thư mục:  
     `mobile/android/app/google-services.json`

---

### Bước 2.3: Cấu hình Ứng Dụng iOS (Nếu chạy trên iOS / macOS)

1. Mở file [mobile/ios/Runner/Info.plist](file:///d:/Vscode/StockMate/mobile/ios/Runner/Info.plist).
2. Thêm khối `CFBundleURLTypes` chứa **Reversed Client ID** của iOS OAuth Client vào trước thẻ `</dict>` cuối cùng:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <!-- Thay bằng REVERSED_CLIENT_ID của bạn -->
               <string>com.googleusercontent.apps.1234567890-abcdefgh</string>
           </array>
       </dict>
   </array>
   ```

---

### Bước 2.4: Cấu hình Flutter Web (Nếu chạy web `flutter run -d chrome`)

Mở file [mobile/web/index.html](file:///d:/Vscode/StockMate/mobile/web/index.html), thêm thẻ meta sau vào bên trong `<head>`:
```html
<meta name="google-signin-client_id" content="your-web-client-id.apps.googleusercontent.com">
```

---

## 3. Danh Sách Các File Đã Được Triển Khai

### A. Phía Backend (FastAPI + PostgreSQL)

| STT | File | Thay đổi chính |
|:---:|---|---|
| 1 | [backend/requirements.txt](file:///d:/Vscode/StockMate/backend/requirements.txt) | Bổ sung `google-auth>=2.35.0` và `requests>=2.32.0`. Đã cài đặt vào venv. |
| 2 | [backend/app/core/config.py](file:///d:/Vscode/StockMate/backend/app/core/config.py) | Thêm cấu hình `GOOGLE_CLIENT_ID` và field validator thông minh cho `DEBUG`. |
| 3 | [backend/.env.example](file:///d:/Vscode/StockMate/backend/.env.example) | Khai báo mẫu biến môi trường `GOOGLE_CLIENT_ID`. |
| 4 | [backend/.env](file:///d:/Vscode/StockMate/backend/.env) | Bổ sung dòng cấu hình `GOOGLE_CLIENT_ID=` sẵn sàng để dán Client ID. |
| 5 | [backend/app/schemas/auth.py](file:///d:/Vscode/StockMate/backend/app/schemas/auth.py) | Thêm schema `GoogleLoginRequest(id_token: str)`. |
| 6 | [backend/app/services/google_auth_service.py](file:///d:/Vscode/StockMate/backend/app/services/google_auth_service.py) | **(MỚI)** Triển khai dịch vụ xác thực token Google, tự động liên kết tài khoản hoặc tạo mới kèm tài khoản đầu tư. |
| 7 | [backend/app/api/v1/endpoints/auth.py](file:///d:/Vscode/StockMate/backend/app/api/v1/endpoints/auth.py) | Thêm API endpoint `POST /api/auth/google`. |
| 8 | [backend/tests/unit/test_google_auth.py](file:///d:/Vscode/StockMate/backend/tests/unit/test_google_auth.py) | **(MỚI)** Bộ unit test kiểm tra validate schema, token hết hạn/sai lệch, thiếu email và auto-link tài khoản. *(Đã pass 100%)* |

### B. Phía Mobile App (Flutter + Riverpod)

| STT | File | Thay đổi chính |
|:---:|---|---|
| 9 | [mobile/pubspec.yaml](file:///d:/Vscode/StockMate/mobile/pubspec.yaml) | Bổ sung dependency `google_sign_in: ^6.2.2`. |
| 10 | [mobile/lib/core/services/google_sign_in_service.dart](file:///d:/Vscode/StockMate/mobile/lib/core/services/google_sign_in_service.dart) | **(MỚI)** Service tương tác với Google SDK, mở giao diện đăng nhập và trả về `id_token`. |
| 11 | [mobile/lib/core/network/api_endpoints.dart](file:///d:/Vscode/StockMate/mobile/lib/core/network/api_endpoints.dart) | Thêm hằng số `ApiEndpoints.authGoogle = '/api/auth/google'`. |
| 12 | [mobile/lib/data/datasources/auth_datasource.dart](file:///d:/Vscode/StockMate/mobile/lib/data/datasources/auth_datasource.dart) | Thêm hàm `googleLogin(String idToken)` gọi POST lên backend. |
| 13 | [mobile/lib/data/repositories/auth_repository.dart](file:///d:/Vscode/StockMate/mobile/lib/data/repositories/auth_repository.dart) | Thêm hợp đồng `Future<UserModel> googleLogin(String idToken);`. |
| 14 | [mobile/lib/data/repositories/api_auth_repository.dart](file:///d:/Vscode/StockMate/mobile/lib/data/repositories/api_auth_repository.dart) | Implement lưu trữ tokens và parse `UserModel`. |
| 15 | [mobile/lib/data/repositories/mock_auth_repository.dart](file:///d:/Vscode/StockMate/mobile/lib/data/repositories/mock_auth_repository.dart) | Cung cấp mock user cho chế độ chạy demo không cần mạng. |
| 16 | [mobile/lib/features/auth/providers/auth_provider.dart](file:///d:/Vscode/StockMate/mobile/lib/features/auth/providers/auth_provider.dart) | Thêm action `googleLogin(idToken)` cập nhật trạng thái Riverpod. |
| 17 | [mobile/lib/features/auth/screens/login_screen.dart](file:///d:/Vscode/StockMate/mobile/lib/features/auth/screens/login_screen.dart) | Gắn hàm `_googleSignIn` vào nút Google, tự động chuyển vào `/home/overview`. |
| 18 | [mobile/lib/features/auth/screens/register_screen.dart](file:///d:/Vscode/StockMate/mobile/lib/features/auth/screens/register_screen.dart) | Gắn hàm `_googleSignIn` vào nút Google ở màn Đăng ký. |

---

## 4. Kiểm Thử & Xác Minh (Verification Results)

### Kiểm thử tự động (Unit Test Backend)
Đã chạy bộ test tự động tại `backend/tests/unit/test_google_auth.py`:
- `test_google_login_schema_validation`: **PASSED**
- `test_google_login_invalid_token`: **PASSED**
- `test_google_login_missing_email`: **PASSED**
- `test_google_login_existing_user_auto_link`: **PASSED**

Toàn bộ 37 bài test checkpoint auth gốc vẫn **PASSED 100%**.

---

## 5. Hướng Dẫn Khởi Động & Thử Nghiệm

1. **Khởi động Backend**:
   ```powershell
   cd backend
   .\.venv\Scripts\activate
   uvicorn app.main:app --reload --port 8000
   ```
2. **Khởi động Mobile App**:
   ```powershell
   cd mobile
   flutter pub get
   flutter run
   ```
3. Nhấp vào nút **Google** tại màn hình Đăng Nhập hoặc Đăng Ký để trải nghiệm luồng đăng nhập một chạm tức thì!
