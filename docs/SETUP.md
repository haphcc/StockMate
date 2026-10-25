# Cài và chạy từng bước

Chạy lệnh từ thư mục gốc repo, trừ khi có `cd backend`/`cd mobile`.
Lệnh bên dưới dành cho PowerShell. Không cần đổi ExecutionPolicy: gọi thẳng Python trong .venv.

## A. Kiểm tra máy — cả 6 người

```powershell
git --version
python --version
docker version
flutter --version
flutter doctor -v
```

Chuẩn nhóm: Python 3.13 (3.14 cũng dùng để kiểm tra nền), PostgreSQL 16, Flutter 3.47.5
và Dart ≥3.13 theo `pubspec.lock`, JDK 17, Android SDK + emulator.
Không chỉ cài Dart 3.10 theo khai báo cũ rồi kỳ vọng lock hiện tại chạy được.
Docker daemon phải có mục Server; lỗi named pipe nghĩa là cần mở Docker Desktop và chờ engine chạy.
Máy FE vẫn cần chạy API bằng Docker hoặc dùng IP máy LB; không cần cài Python nếu chỉ dùng Docker.

## B. Cách dễ nhất: Docker cho API + DB

```powershell
docker compose up -d --build
docker compose ps
docker compose exec api python -m alembic upgrade head
docker compose exec api python -m scripts.seed_demo
Invoke-RestMethod http://localhost:8000/health/live
Invoke-RestMethod http://localhost:8000/health/ready
```

Kết quả:

- Migration tạo baseline 9 bảng + function/trigger/view và `alembic_version`.
- Seed tạo 83 mã, 10 khách hàng, 13 account; mật khẩu demo được hash thật bằng bcrypt.
- Live trả `status=ok`; ready trả `database=connected`.
- Mở http://localhost:8000/docs xem các endpoint và nút Try it out.
- Gọi login hiện trả **501** là đúng trạng thái khung, không phải DB đã đăng nhập thành công.
- Seed chỉ cho DB trống. Chạy lại sẽ từ chối; không có reset ngầm.

Nếu 5432 bận: sửa port host Compose, ví dụ `127.0.0.1:5433:5432`; API trong Docker vẫn dùng db:5432.
Nếu 8000 bận: sửa port host API và API_BASE_URL của mobile cùng lúc.
Schema không tự migrate mỗi lần server khởi động; Phuoc chạy migration chủ động theo từng PR.

Xem log/dừng mà giữ dữ liệu:

```powershell
docker compose logs --tail 100 api
docker compose stop
docker compose start
```

## C. Backend local để LB/Tuệ phát triển

Từ repo gốc, chỉ chạy DB bằng Docker:

```powershell
docker compose up -d db
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.lock.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m scripts.seed_demo
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Chỉ copy .env lần đầu; không ghi đè cấu hình riêng đang dùng.
Nếu đã migrate/seed ở bước B thì bỏ hai lệnh đó tại C. Dừng API Docker để nhường cổng 8000:
`docker compose stop api` (từ repo gốc).
`.env` local dùng localhost; Compose đặt DATABASE_URL riêng theo hostname `db`.
Khi bắt đầu auth, LB đọc SECRET_KEY từ env, dùng khóa tự sinh thay placeholder, fail startup khi cấu hình sai.

Tài khoản demo sau khi BE-01 được triển khai: `an.nguyen@gmail.com` / `Matkhau@123`.
Không dùng tài khoản đăng ký mới trùng email/SĐT seed.

## D. Mobile — Sơn/Me/Châu

Mở terminal khác, từ repo gốc:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run --dart-define=USE_MOCK=true
```

Mock là giao diện hiện có, chưa chứng minh luồng thật. Sau FE-02 + BE-01/02 mới chạy:

```powershell
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

| Thiết bị | API_BASE_URL |
|---|---|
| Android Emulator của Android Studio | `http://10.0.2.2:8000` |
| iOS simulator/macOS | `http://localhost:8000` |
| Máy thật cùng Wi-Fi | `http://<IPv4-máy-chạy-API>:8000` |
| Flutter web dev | `http://localhost:8000` |

Máy thật không dùng localhost/10.0.2.2 của emulator. API phải bind 0.0.0.0 và firewall cho phép cổng dev.
Android HTTP dev cần cấu hình cleartext **chỉ ở debug**; TV2 phụ trách, không mở toàn bộ release.
Web dùng cổng cố định để khớp CORS: `flutter run -d chrome --web-port 8080 --dart-define=USE_MOCK=true`.
Đổi origin thì sửa BACKEND_CORS_ORIGINS tương ứng; không thay bằng wildcard.

## E. Lệnh kiểm tra trước khi bàn giao

Từ `backend/`:

```powershell
.\.venv\Scripts\python.exe -m ruff check app scripts tests alembic
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m scripts.export_openapi --check
```

Từ repo gốc: `python scripts/check_preparation.py` (kiểm tra link, ownership, cấu trúc).
Từ `mobile/`: `flutter analyze`, `flutter test`.
Đổi schema API: chạy export không `--check`, rồi commit `backend/openapi.json` cùng schema.

## F. Lỗi thường gặp

| Hiện tượng | Làm gì |
|---|---|
| `No module named app` | Đang ở sai thư mục; cd backend, dùng Python .venv |
| `ModuleNotFoundError` sau khi pip install | Kiểm tra đang dùng cùng executable .venv cho pip/server/test |
| `DATABASE_UNAVAILABLE` | Kiểm tra Docker, port, DATABASE_URL, postgres user/password |
| Baseline báo existing tables | DB đã có prototype; dùng DB dev mới theo DATABASE_WORKFLOW, không stamp mù |
| Seed từ chối có dữ liệu | Seed đã chạy hoặc có dữ liệu dở; dùng DB mới, không chạy script reset |
| Login 501 | BE-01 chưa triển khai; xem task, không sửa thành trả token giả |
| USE_MOCK=false ném UnimplementedError | FE-02 chưa triển khai API repositories |
| JSON tiền parse lỗi | Model cũ đọc num; sửa theo contract string Decimal |
| Flutter test tải font/network | Sơn mock platform/font theo task FE-01; không xóa test để né lỗi |
| Thiếu Android SDK | Cài Android Studio SDK/emulator, chạy doctor và android-licenses |

macOS/Linux thay `.venv\Scripts\python.exe` bằng `.venv/bin/python`; dùng `cp .env.example .env`.
