# StockMate

Ứng dụng Flutter mô phỏng giao dịch chứng khoán Việt Nam; backend FastAPI, database PostgreSQL.

**Bắt đầu ở [START_HERE](docs/START_HERE.md).**

- [Kế hoạch 3 chặng](docs/PLAN.md): làm gì trước, làm gì sau.
- [Phân công 6 người](docs/TASK_ASSIGNMENT.md): ai làm phần nào, sửa file nào.
- [Bảng tiến độ](docs/WORK_BOARD.md): cập nhật việc đang làm.
- [Cài môi trường](docs/SETUP.md): chuẩn bị máy và chạy giao diện có sẵn.

---

## 1. Khởi tạo Cơ sở dữ liệu & Dữ liệu mẫu (TV1 — Phuoc đã hoàn thành)

Dành cho các thành viên (**LB, Tuệ, Sơn, Châu...**) khi mới tải project về:

### Bước 1: Dùng PostgreSQL cài trên máy

StockMate kết nối trực tiếp tới PostgreSQL local, không dùng container database.
Tạo database `stock_exchange` trên PostgreSQL local của bạn (xem lệnh ở bước 2).

### Bước 2: Cấu hình biến môi trường
Vào thư mục `backend/` và copy file cấu hình mẫu (nếu chưa có):
```powershell
cd backend
copy .env.example .env
```
Thiết lập `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`,
`POSTGRES_PASSWORD` và `DATABASE_URL` khớp với PostgreSQL local của bạn.
Ví dụ PostgreSQL local chạy ở cổng `55432`:

```dotenv
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=55432
POSTGRES_DB=stock_exchange
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<mat-khau-postgres-local>
DATABASE_URL=postgresql+psycopg://postgres:<mat-khau-postgres-local>@127.0.0.1:55432/stock_exchange
```

Tạo database (đổi host, port, user nếu cần):

```powershell
cd backend
.\.venv\Scripts\python.exe scripts\create_local_database.py
```

### Bước 3: Cài đặt thư viện Python backend
Từ thư mục `backend/`:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.lock.txt
```

### Bước 4: Tạo cấu trúc bảng và nạp dữ liệu mẫu
Từ thư mục `backend/`:
```powershell
alembic upgrade head
python scripts/seed_demo.py
```
> [!NOTE]
> * Lệnh `alembic upgrade head` sẽ tạo đầy đủ 9 bảng, 6 view, stored procedure T+2 và trigger khớp lệnh.
> * Lệnh `python scripts/seed_demo.py` sẽ nạp 90 mã cổ phiếu (đủ 30/30 mã VN30), 10 khách hàng và 13 tài khoản CASH/MARGIN.
> * **Mật khẩu đăng nhập demo của tất cả tài khoản:** `Matkhau@123` (đã hash Bcrypt thật).

---

## 2. Chạy ứng dụng Flutter Mobile (Frontend)

Từ thư mục gốc của repo:

```powershell
cd mobile
flutter pub get
flutter run
```
*(Nếu dùng máy ảo Android emulator, kết nối API backend qua địa chỉ `http://10.0.2.2:8000`)*.
