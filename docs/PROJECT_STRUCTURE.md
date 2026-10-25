# Cây dự án và trách nhiệm từng phần

Cây này mô tả các file thực tế trong repo sau bước chuẩn bị. File TODO là vị trí để người phụ trách
triển khai; không được tính là feature hoàn thành. Toàn bộ inventory nằm trong [FILE_OWNERS.md](FILE_OWNERS.md).

```text
StockMate/
├── README.md                         TV1: lối vào dự án
├── compose.yaml                      TV1: TODO PostgreSQL + API
├── .github/workflows/checks.yml      TV1: CI khung/docs; Flutter thủ công
├── scripts/check_preparation.py      TV6: link, ownership, inventory
├── docs/
│   ├── START_HERE.md                 TV1: thứ tự bắt đầu
│   ├── MVP_SCOPE.md                  TV1: phạm vi bản đầu
│   ├── BUSINESS_RULES.md             TV1 + TV5: luật và ví dụ số
│   ├── API_CONTRACT.md               TV4: wire format/API
│   ├── contracts/examples.json       TV4: dữ liệu mẫu cho FE/test
│   ├── SETUP.md                      TV1: hướng dẫn chạy
│   ├── DATABASE_WORKFLOW.md          TV1: migration/seed/khoảng trống
│   ├── PROJECT_STRUCTURE.md          TV1: tài liệu này
│   ├── FILE_OWNERS.json              TV1: quy tắc chủ file, máy đọc
│   ├── FILE_OWNERS.md                sinh từ JSON: danh sách từng file
│   ├── WORK_BOARD.md                 TV6: task, dependency, trạng thái
│   ├── ACCEPTANCE_TESTS.md           TV6: expected và bằng chứng
│   ├── team/TV1_... đến TV6_...       mỗi người: checklist riêng
│   └── qa/                          TV6: môi trường, bug, demo evidence
├── data/postgres/                    TV1: prototype và dữ liệu seed
├── backend/
│   ├── requirements.txt/lock.txt     TV4: dependency đầu vào/đã khóa
│   ├── Dockerfile                   TV1
│   ├── pyproject.toml               TV4: ruff + pytest
│   ├── alembic.ini                  TV1
│   ├── alembic/
│   │   ├── env.py                   TV1: TODO cấu hình migration
│   │   ├── sql/0001_*.sql           TV1: TODO SQL do Phuoc tự viết
│   │   └── versions/0001_baseline.py TV1: TODO revision đầu tiên
│   ├── app/
│   │   ├── main.py                  TV4: ghép app, middleware, router
│   │   ├── api/deps.py              TV4: current user/JWT dependency
│   │   ├── api/v1/api.py            TV4: đăng ký router
│   │   ├── api/v1/endpoints/
│   │   │   ├── health.py            TV4: TODO health
│   │   │   ├── auth.py              TV4: TODO BE-01
│   │   │   ├── market.py            TV4: TODO BE-02/03
│   │   │   ├── accounts.py          TV4: TODO BE-02/03
│   │   │   ├── watchlist.py         TV4: TODO BE-03
│   │   │   ├── orders.py            TV5: TODO TR-02
│   │   │   ├── transactions.py      TV5: TODO TR-02
│   │   │   └── notifications.py     TV5: TODO TR-02
│   │   ├── core/
│   │   │   ├── config.py/errors.py  TV4: TODO config/errors
│   │   │   └── security.py          TV4: TODO BE-01
│   │   ├── db/session.py            TV4: TODO engine/session
│   │   ├── db/base.py               TV4: TODO BE-01
│   │   ├── models/                  TV4/TV5: TODO mapping từng bảng
│   │   ├── schemas/                 TV4/TV5: TODO request/response
│   │   ├── crud/                    TV4/TV5: TODO queries theo nhóm
│   │   └── services/                TV4/TV5: TODO use case theo nhóm
│   ├── scripts/
│   │   ├── export_openapi.py        TV4: TODO exporter OpenAPI
│   │   ├── seed_demo.py             TV1: TODO seed an toàn
│   │   ├── settle_shares.py         TV5: TODO TR-03
│   │   └── sync_market_data.py      TV4: TODO mở rộng BE-04
│   └── tests/
│       ├── conftest.py              TV6: TODO HTTP fixture
│       ├── unit/                    TV6 nền; auth TV4, trading/settlement TV5
│       └── integration/             TV6: PostgreSQL thật, phối hợp người viết feature
└── mobile/
    ├── pubspec.yaml/lock            TV2: package chung
    ├── android/ios/web/             TV1: nền tảng; HTTP debug TV2
    ├── assets/                      TV2: tài nguyên giao diện dùng chung
    ├── lib/
    │   ├── main.dart                TV2
    │   ├── core/
    │   │   ├── config/app_config.dart TV2: useMock=true gốc; TODO chọn môi trường
    │   │   ├── network/             TV2: Dio gốc; TODO endpoints/lỗi API
    │   │   ├── storage/             TV2: TODO tokens
    │   │   ├── utils/               TV2: format/validate + TODO tiền chính xác
    │   │   ├── router/              TV2: router chung, Me bàn giao route cần thêm
    │   │   └── theme/widgets/       TV2: dùng lại toàn app
    │   ├── providers/               TV2: app providers + TODO selected account
    │   ├── data/
    │   │   ├── models/              TV2: user/account/portfolio; TV3: stock/candle/trading
    │   │   ├── datasources/         TODO TV2: auth/market; TV3: trading/watchlist/notification
    │   │   └── repositories/        TV2: auth/market mock + API; TV3: trading/watchlist/notification
    │   └── features/
    │       ├── auth/               TV2: UI có sẵn, phải nối API/validation
    │       ├── home/               TV2: UI có sẵn, phải thay hardcode
    │       ├── portfolio/          TV2: UI có sẵn + provider TODO
    │       ├── profile/            TV2: để sau, không tính MVP
    │       ├── market/             TV3: TODO board/detail/provider
    │       ├── watchlist/          TV3: TODO screen/provider
    │       ├── order/              TV3: UI có sẵn + provider TODO
    │       ├── transaction/        TV3: TODO history/provider
    │       └── notification/       TV3: TODO list/provider
    ├── test/                       TV6; test model theo chủ file feature
    └── integration_test/           TV6: chỗ viết luồng app thật
```

## Chọn đúng loại file

| Bạn cần làm | Viết vào | Không đặt ở |
|---|---|---|
| Khai báo field JSON/validation request | backend schemas | SQL migration hoặc widget |
| Xác thực/chọn user hiện tại | api/deps + core/security | Mỗi endpoint tự verify một kiểu |
| Query SQL, filter owner | crud | Widget/client |
| Một use case atomic, khóa và gọi routine | services | CRUD tự commit rải rác |
| Thay cột/constraint/trigger | migration mới | Chạy SQL tay vào DB chung |
| Gọi HTTP/map DTO | mobile datasource/repository | Widget gắn URL trực tiếp |
| Loading/cache/selected account/invalidation | mobile providers | Biến global không theo user/account |
| Hiển thị và thao tác người dùng | feature screens/widgets | Model tự gọi API |

Luồng: Flutter screen → provider → repository → datasource/Dio → endpoint → service → CRUD/SQL routine.
Services có thể dùng query trực tiếp phù hợp với repo hiện tại; không tạo thêm lớp chỉ để chuyển tiếp.

## File khung khác file đã chạy

File Python chỉ có docstring TODO và file Dart chỉ có comment TODO chưa định nghĩa chức năng.
Toàn bộ Python backend bổ sung hiện chỉ là TODO; chưa có schema, route hoặc app thực thi.
OpenAPI chưa tồn tại, LB sinh sau khi có app. Docker/Alembic/SQL mới cũng chỉ là TODO.
Giữ code Flutter và SQL prototype gốc; không trả dữ liệu/token giả để nhận là luồng API thật.

## Thêm file mới

1. Đặt trong đúng feature/nhóm ở trên, theo snake_case hiện có.
2. Tra FILE_OWNERS.json; thêm rule cụ thể nếu chủ file khác rule thư mục.
3. `python scripts/check_preparation.py --write-owners`.
4. Sửa hướng dẫn task nếu file mới thay đổi điểm bàn giao; commit cùng feature.
