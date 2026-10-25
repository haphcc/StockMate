# StockMate

Ứng dụng giao dịch chứng khoán trên di động, mô phỏng thị trường Việt Nam (HOSE / HNX / UPCOM).

**Nhóm bắt đầu ở [docs/START_HERE.md](docs/START_HERE.md)**: phạm vi MVP, thứ tự làm,
file từng người quản lý và hướng dẫn cầm tay chỉ việc cho 6 thành viên.

| Cần tìm | Mở |
|---|---|
| Cài/chạy từng bước | [SETUP](docs/SETUP.md) |
| Phạm vi và luật giao dịch | [MVP_SCOPE](docs/MVP_SCOPE.md), [BUSINESS_RULES](docs/BUSINESS_RULES.md) |
| API và JSON mẫu | [API_CONTRACT](docs/API_CONTRACT.md), [examples](docs/contracts/examples.json) |
| Cây file và người quản lý | [PROJECT_STRUCTURE](docs/PROJECT_STRUCTURE.md), [FILE_OWNERS](docs/FILE_OWNERS.md) |
| Việc tiếp theo và nghiệm thu | [WORK_BOARD](docs/WORK_BOARD.md), [ACCEPTANCE_TESTS](docs/ACCEPTANCE_TESTS.md) |

| Tầng | Công nghệ | Thư mục |
|---|---|---|
| Frontend | Flutter + Dart (Android, iOS) | [`mobile/`](mobile/README.md) |
| Backend | FastAPI (Python) | [`backend/`](backend/README.md) |
| Database | PostgreSQL | [`data/`](data/README.md) |

## Kế hoạch & Phân công dự án

- 📑 [Kế hoạch phát triển chi tiết 3 Sprint (PLAN.md)](docs/PLAN.md)
- 👥 [Phân công công việc 6 thành viên & RACI (TASK_ASSIGNMENT.md)](docs/TASK_ASSIGNMENT.md)
- Kế hoạch cũ giữ làm định hướng; bản đầu triển khai theo MVP_SCOPE và WORK_BOARD ở trên.

## Bắt đầu

```bash
git clone https://github.com/haphcc/StockMate.git
cd StockMate
```

**1. API + Database** — từ thư mục gốc, Docker Desktop phải đang chạy:

```bash
docker compose up -d --build
docker compose exec api python -m alembic upgrade head
docker compose exec api python -m scripts.seed_demo
```

API chạy ở `http://localhost:8000`, Swagger `/docs`; liveness `/health/live`,
DB connectivity `/health/ready`. Endpoint nghiệp vụ hiện trả 501 có chủ ý.
Backend local: theo [SETUP](docs/SETUP.md). Migration yêu cầu DB trống; seed không reset dữ liệu.

**2. Mobile** — chạy giao diện mock trên emulator Android hoặc iOS simulator:

```bash
cd mobile
flutter pub get
flutter run --dart-define=USE_MOCK=true
```

Base URL mặc định là Android emulator `http://10.0.2.2:8000`; iOS phải override thành
`http://localhost:8000`. Chỉ bật USE_MOCK=false sau khi hoàn thành FE-02.

## Trạng thái

| Phần | Trạng thái |
|---|---|
| Database | Có prototype, migration baseline và seed; engine cần TR-01/02/03 |
| Backend | Có app/health/config/schema/OpenAPI; nghiệp vụ là contract stub 501 |
| Mobile | Có UI mock/auth/dashboard/order/portfolio; API repositories là TODO |
| Phân công | Có người quản lý từng file, checklist riêng 6 người và acceptance cases |

Hợp đồng chuẩn: [API_CONTRACT](docs/API_CONTRACT.md), schema Python và
[OpenAPI snapshot](backend/openapi.json).

## Quy ước chung

- Tiền và giá lưu bằng `NUMERIC`, Python `Decimal`; JSON là string 2 chữ số lẻ.
  Flutter dùng Decimal hoặc số nguyên chính xác đơn vị 0.01 đồng, không qua double.
- Backend điều phối transaction/khóa/ownership; routine DB tính và apply giao dịch.
  Trigger prototype chưa đủ reserve/release/T+2; theo [DATABASE_WORKFLOW](docs/DATABASE_WORKFLOW.md).
- Màu bảng giá theo quy ước Việt Nam: trần tím, sàn xanh lơ, tham chiếu vàng,
  tăng xanh lá, giảm đỏ (view `v_market_board` trả sẵn cột `price_state`).
- Không commit `.env`, keystore, file cấu hình ký ứng dụng.
