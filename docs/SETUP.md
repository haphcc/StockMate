# Chuẩn bị máy

| Ai | Cần cài |
|---|---|
| Phuoc, LB, Tuệ | Python 3.13, PostgreSQL 16 hoặc Docker Desktop |
| Sơn, Me (TV3) | Flutter 3.47.5 / Dart theo lock, Android Studio/SDK, JDK 17, emulator |
| Châu | Công cụ của phần đang kiểm thử; cần chạy được cả app và backend để thử tích hợp |

Cả nhóm dùng Git. iOS cần macOS/Xcode; trước mắt bàn giao APK Android.

## Chạy Flutter có sẵn

Từ thư mục gốc repo:

```powershell
cd mobile
flutter pub get
flutter run
```

Nếu chưa chạy được, dùng `flutter doctor -v` để xem phần còn thiếu.
App hiện dùng mock; Sơn tự viết lựa chọn mock/API khi nối backend.

## Chuẩn bị backend

Từ thư mục gốc repo:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.lock.txt
```

Chỉ copy .env.example thành .env nếu chưa có, chỉnh DATABASE_URL/SECRET_KEY cho máy mình.
Backend CP1 và migration/seed đã có implementation. Làm theo
[backend README](../backend/README.md) để migrate, seed, chạy Uvicorn và thử API auth/accounts.
Các API thị trường/tài sản/giao dịch còn theo tiến độ của chủ phần.

Khi có API, Android emulator dùng http://10.0.2.2:8000; máy thật dùng IP máy chạy API cùng Wi-Fi.

## Kiểm tra trước bàn giao

- Từ mobile: `flutter analyze` và `flutter test`.
- Từ backend: Ruff check/format; khi có test thật thì chạy pytest.

CI `checks` kiểm tra lint/format/compile và chạy migration, seed, pytest, OpenAPI trên
PostgreSQL 16/Python 3.13 khi push `main`, `traidep` hoặc mở PR. Flutter checks bật thủ công.
Chi tiết dựng DB nằm ở [DATABASE_WORKFLOW](DATABASE_WORKFLOW.md).
Không chạy script reset prototype lên DB cần giữ dữ liệu; không commit .env/khóa ký.
