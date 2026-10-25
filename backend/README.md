# StockMate — Backend

Đây là cấu trúc để LB, Tuệ và Phuoc tự triển khai. Các file Python chỉ chứa TODO có chủ.
Chưa có app.main:app, route, schema thực thi, DB session, migration, seed hay test nghiệp vụ.

## Chuẩn bị

Từ thư mục backend trên PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.lock.txt
```

Chỉ copy .env.example thành .env nếu chưa có cấu hình riêng. Dependency lock là phần chuẩn bị,
không có nghĩa ứng dụng đã được viết. Dockerfile/Compose và Alembic hiện là TODO.

## Viết theo thứ tự

1. Phuoc làm ENV-01: PostgreSQL, Compose, Alembic, schema và seed an toàn.
2. LB làm BE-01: Settings, FastAPI app, DB session/models, lỗi, health, schema và auth.
3. LB nối router/API; Tuệ triển khai nghiệp vụ theo BUSINESS_RULES.
4. Châu viết fixture/test; LB viết tool export OpenAPI và sinh snapshot khi app đã có.
5. Phuoc/Châu bật kiểm tra DB/API đầy đủ trong CI khi có implementation.

Sau bước 2 mới có thể chạy `uvicorn app.main:app --reload`.
Hiện chạy pytest sẽ chưa có test thực thi; file test TODO không phải test đã pass.

Tra [START_HERE](../docs/START_HERE.md), [SETUP](../docs/SETUP.md),
[API_CONTRACT](../docs/API_CONTRACT.md), [DATABASE_WORKFLOW](../docs/DATABASE_WORKFLOW.md),
[TV4 — LB](../docs/team/TV4_LB.md), [TV5 — Tuệ](../docs/team/TV5_TUE.md).
