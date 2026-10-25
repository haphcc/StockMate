# Chuẩn bị máy và bắt đầu triển khai

Hiện chỉ giữ khung/TODO và hướng dẫn. Code database/frontend gốc của nhóm vẫn giữ nguyên.
Các lệnh chạy backend, migration, seed hoặc Docker chỉ dùng sau khi người phụ trách đã viết chúng.

## A. Kiểm tra công cụ

```powershell
git --version
python --version
docker version
flutter --version
flutter doctor -v
```

Mục tiêu: Python 3.13, PostgreSQL 16, Flutter 3.47.5 / Dart theo pubspec.lock,
JDK 17, Android SDK và emulator. Người làm iOS cần macOS/Xcode.

## B. Backend — LB/Tuệ

Từ repo gốc:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.lock.txt
```

Chỉ copy .env.example thành .env nếu chưa có. LB tự viết Settings đọc environment,
FastAPI app, errors, health và schema trước khi nối endpoint. Phuoc bàn giao DB/session configuration.
Chưa chạy Uvicorn: app/main.py hiện chỉ là TODO.

## C. Database và Docker — Phuoc

1. Đọc DATABASE_WORKFLOW và SQL prototype có sẵn trong data/postgres.
2. Tự viết Dockerfile/Compose, PostgreSQL có volume và healthcheck.
3. Khởi tạo Alembic bằng cấu hình/template thật; viết revision và SQL ban đầu từ thiết kế đã review.
4. Tự viết seed chạy một lần, hash mật khẩu thật, từ chối DB có dữ liệu, không reset.
5. Test migrate/seed trên DB DEV mới; Châu kiểm tra chạy lại và rollback.
6. Sau khi LB có app, thêm API service, kiểm tra /health/live và /health/ready rồi ghi bằng chứng.

compose.yaml, Dockerfile, alembic.ini và các file SQL hiện chỉ là TODO.
Chưa dùng `docker compose up`, `alembic upgrade head` hay `scripts.seed_demo` để dựng DB từ khung này.
Không dùng 00_run_all.sql trên DB dùng chung: script gốc có DROP.

## D. Chạy Flutter gốc — Sơn/Me

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

AppConfig.useMock vẫn là true trong code gốc. Sơn tự thêm chọn môi trường ở FE-02;
`--dart-define=USE_MOCK=false` chưa có hiệu lực ở trạng thái này.
UI/mock có sẵn chưa chứng minh API/backend hoạt động. Các lỗi lint gốc do Sơn xử lý trong FE-01.

| Thiết bị | API URL sau khi backend và cấu hình FE-02 đã có |
|---|---|
| Android emulator | http://10.0.2.2:8000 |
| iOS simulator | http://localhost:8000 |
| Máy thật cùng Wi-Fi | http://<IP-máy-API>:8000 |

LB cấu hình CORS; Sơn cấu hình HTTP debug/signing. Không mở HTTP release thay cho HTTPS.

## E. Kiểm tra khung hiện tại

Từ repo gốc: `python scripts/check_preparation.py`.
Từ backend: `python -m ruff check app scripts tests alembic` và
`python -m ruff format --check app scripts tests alembic` sau khi cài dependency.

CI tự động chỉ kiểm tra tài liệu/ownership, lint/format và cú pháp khung Python.
Flutter có thể chạy thủ công trong Actions → checks → Run workflow → run_mobile_checks.
Phuoc/Châu tự thêm migration/seed/pytest/OpenAPI vào CI sau khi các task có code thật.
Không tính CI khung xanh thành nghiệm thu backend/database/frontend.
