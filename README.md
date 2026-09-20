# StockMate

Ứng dụng giao dịch chứng khoán trên di động, mô phỏng thị trường Việt Nam (HOSE / HNX / UPCOM).

| Tầng | Công nghệ | Thư mục |
|---|---|---|
| Frontend | Flutter + Dart (Android, iOS) | [`mobile/`](mobile/README.md) |
| Backend | FastAPI (Python) | [`backend/`](backend/README.md) |
| Database | PostgreSQL | [`data/`](data/README.md) |

## Bắt đầu

```bash
git clone https://github.com/haphcc/StockMate.git
cd StockMate
```

**1. Database** — tạo DB và nạp schema + dữ liệu mẫu (83 mã, 10 khách hàng, lịch sử giá 130 phiên):

```bash
cd data/postgres
psql -h localhost -U postgres -d stock_exchange -f 00_run_all.sql
```

**2. Backend** — API chạy ở `http://localhost:8000`, docs ở `/docs`:

```bash
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**3. Mobile** — chạy trên emulator Android hoặc iOS simulator:

```bash
cd mobile
flutter pub get
flutter run
```

Base URL mặc định: Android emulator `http://10.0.2.2:8000`, iOS simulator `http://localhost:8000`.
Đổi bằng `flutter run --dart-define=API_BASE_URL=...`.

## Trạng thái

| Phần | Trạng thái |
|---|---|
| Database | Xong schema, trigger nghiệp vụ, view và dữ liệu mẫu |
| Backend | Mới có khung thư mục + cấu hình, chưa có code |
| Mobile | Đã `flutter create` (android/ + ios/), khung thư mục `lib/`, chưa có code |

Danh sách endpoint đã thống nhất giữa backend và mobile: xem mục 3 của
[`backend/README.md`](backend/README.md).

## Quy ước chung

- Tiền và giá lưu bằng `NUMERIC`, đơn vị **đồng** → dùng `Decimal` (Python) / `Decimal`
  hoặc `num` có kiểm soát làm tròn (Dart), **không dùng `float`**.
- Nghiệp vụ khớp lệnh (cập nhật danh mục, giá vốn bình quân, số dư, T+2, phí và thuế)
  nằm trong trigger của PostgreSQL — backend chỉ ghi vào `transactions`.
- Màu bảng giá theo quy ước Việt Nam: trần tím, sàn xanh lơ, tham chiếu vàng,
  tăng xanh lá, giảm đỏ (view `v_market_board` trả sẵn cột `price_state`).
- Không commit `.env`, keystore, file cấu hình ký ứng dụng.
