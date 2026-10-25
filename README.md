# StockMate

Ứng dụng mô phỏng giao dịch chứng khoán Việt Nam (HOSE / HNX / UPCOM).

Bắt đầu tại [START_HERE](docs/START_HERE.md): phạm vi, phân công và checklist cho 6 thành viên.

## Trạng thái hiện tại

Theo yêu cầu của nhóm, phần implementation bổ sung trong bước chuẩn bị đã được gỡ.
Giữ cấu trúc thư mục, file TODO, tài liệu và toàn bộ code có sẵn trước bước chuẩn bị.

| Phần | Hiện trạng |
|---|---|
| Database | SQL prototype gốc tại data/postgres được giữ; Alembic/seed mới là TODO của Phuoc |
| Backend | File khung TODO; chưa có FastAPI app, schema, health hay endpoint chạy được |
| Mobile | Giữ UI/mock và test gốc của nhóm; file bổ sung là TODO, AppConfig.useMock vẫn true |
| Môi trường | Dependency/lock để chuẩn bị; Dockerfile và Compose là TODO |
| CI | Tự kiểm tra khung, tài liệu, ownership và cú pháp; Flutter chạy thủ công nếu chọn |

## Tài liệu làm việc

- [SETUP](docs/SETUP.md): cài công cụ và thứ tự triển khai.
- [MVP_SCOPE](docs/MVP_SCOPE.md), [BUSINESS_RULES](docs/BUSINESS_RULES.md): phạm vi và luật đích.
- [API_CONTRACT](docs/API_CONTRACT.md), [JSON mẫu](docs/contracts/examples.json): đặc tả để nhóm tự code.
- [PROJECT_STRUCTURE](docs/PROJECT_STRUCTURE.md), [FILE_OWNERS](docs/FILE_OWNERS.md): file và người phụ trách.
- [WORK_BOARD](docs/WORK_BOARD.md), [ACCEPTANCE_TESTS](docs/ACCEPTANCE_TESTS.md): việc và điều kiện nghiệm thu.
- [PLAN](docs/PLAN.md), [TASK_ASSIGNMENT](docs/TASK_ASSIGNMENT.md): kế hoạch/phân công có sẵn.

## Chạy giao diện có sẵn

```powershell
cd mobile
flutter pub get
flutter run
```

Đây là UI/mock gốc. Backend, migration, seed và Docker chưa có implementation để chạy.
Sơn tự bổ sung chuyển đổi mock/API trong FE-02; chỉ truyền USE_MOCK chưa thay đổi được code gốc.

## Quy ước

Tiền dùng NUMERIC/Decimal, JSON tiền là string hai số lẻ theo đặc tả.
Không commit .env/khóa ký. Không chạy script reset prototype lên DB có dữ liệu cần giữ.
