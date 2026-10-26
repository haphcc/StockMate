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

Chỉ copy .env.example thành .env nếu chưa có. Backend, Compose, migration và seed hiện là TODO.
Phuoc viết phần DB/môi trường; LB viết app, cấu hình và API. Hai người cập nhật lệnh chạy tại đây
sau khi đã chạy thử; hiện chưa chạy Uvicorn/Docker/migrate từ bộ khung này.

Khi có API, Android emulator dùng http://10.0.2.2:8000; máy thật dùng IP máy chạy API cùng Wi-Fi.

## Kiểm tra trước bàn giao

- Từ mobile: `flutter analyze` và `flutter test`.
- Từ backend: Ruff check/format; khi có test thật thì chạy pytest.

CI tự động hiện chỉ kiểm tra khung/tài liệu. Phuoc/Châu thêm kiểm tra DB/API khi có implementation.
Chi tiết dựng DB nằm ở [DATABASE_WORKFLOW](DATABASE_WORKFLOW.md).
Không chạy script reset prototype lên DB cần giữ dữ liệu; không commit .env/khóa ký.
