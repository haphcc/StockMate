# Viết code ở đâu?

Backend hiện chỉ là TODO; Flutter và SQL prototype gốc vẫn có sẵn.

```text
StockMate/
├── mobile/                  App Flutter — Sơn và Me (TV3)
│   ├── lib/core/            Network, router, theme, helper dùng chung — Sơn
│   ├── lib/data/            Model, datasource, repository — chia theo chức năng
│   ├── lib/providers/       State dùng chung/chọn tài khoản — Sơn
│   ├── lib/features/        Các màn hình — chia theo phân công
│   ├── test/                Test model/widget
│   └── integration_test/    Test luồng app
├── backend/
│   ├── app/main.py          Khởi tạo FastAPI — LB
│   ├── app/api/             Endpoint và xác thực request — LB/Tuệ
│   ├── app/schemas/         JSON request/response và validation — LB/Tuệ
│   ├── app/models/          Mapping bảng database — LB/Tuệ
│   ├── app/crud/            Query dữ liệu — LB/Tuệ
│   ├── app/services/        Xử lý nghiệp vụ — LB/Tuệ
│   ├── app/core/ và db/     Cấu hình, bảo mật, kết nối DB — LB
│   ├── alembic/             Migration/SQL do nhóm tự viết — Phuoc
│   ├── scripts/             Seed: Phuoc; T+2: Tuệ; feed mở rộng: LB
│   └── tests/               Test backend — người viết tính năng và Châu
├── data/postgres/            SQL prototype gốc để tham khảo — Phuoc
├── docs/                     Kế hoạch, phân công, đặc tả, kết quả test
├── compose.yaml              TODO môi trường DB/API — Phuoc
└── .github/workflows/        CI — Phuoc
```

Luồng chính: màn hình Flutter → provider → repository/datasource → API → service → database.
Giữ các lớp đã có; chỉ thêm lớp khi có xử lý cần đặt vào đó.

[TASK_ASSIGNMENT](TASK_ASSIGNMENT.md) chia người theo chức năng;
[FILE_OWNERS](FILE_OWNERS.md) liệt kê chủ từng file. Sơn giữ file Flutter dùng chung,
Phuoc giữ migration, LB/Tuệ chia backend theo endpoint.

Sau khi thêm file, chạy `python scripts/check_preparation.py --write-owners` từ repo gốc.
