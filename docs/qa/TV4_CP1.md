# TV4 — Checkpoint 1: backend auth và tài khoản

Ngày chạy: 27/10/2026 (Asia/Bangkok).
Code: base `3bf4f22` + thay đổi working tree nhánh `codex/tv4-checkpoint-1`;
chưa commit/push tại thời điểm ghi bằng chứng.
Môi trường: Windows, Python 3.14.7, PostgreSQL 18.6 chạy riêng trên loopback cổng 55434.
Schema: `0003_order_uuid_blocked_qty`; dùng Alembic thật, không `create_all`/SQLite.

## Phạm vi đã triển khai

- FastAPI/config/session/health và lỗi `{error: {code, message, details}}`.
- Register tạo customer ACTIVE/CUSTOMER + CASH account ACTIVE + `1000000000.00`
  tiền giả lập trong một transaction; không cấp lại khi login/refresh.
- Login/refresh trả user và JWT access 15 phút, refresh 14 ngày; có claim sub/type/exp/iat.
- `/api/auth/me`, `/api/accounts` lấy đúng user/tài khoản theo JWT; thứ tự account_id ASC.
- Validation email/họ tên/SĐT/mật khẩu, bcrypt không cắt ngầm quá 72 byte UTF-8.
- Kiểm tra type JWT, trạng thái user hiện tại và quyền Admin từ DB.
- Export/check `backend/openapi.json` từ app thật, có schema lỗi đúng envelope.

## Bằng chứng tự động

Từ `backend/`, sau khi migrate/seed database DEV dùng riêng cho test Admin:

```powershell
# DATABASE_URL: DB DEV đã seed cho test Admin có sẵn.
# TEST_DATABASE_URL: server DEV có quyền CREATEDB cho integration CP1.
.\.venv\Scripts\python.exe -m pytest -q --tb=short
.\.venv\Scripts\python.exe -m ruff check app scripts tests alembic
.\.venv\Scripts\python.exe -m ruff format --check app scripts tests alembic
.\.venv\Scripts\python.exe scripts/export_openapi.py --check
.\.venv\Scripts\python.exe -m compileall -q app scripts tests alembic
git diff --check
```

Kết quả thực tế: **70 passed, 3 warnings trong 23.31 giây**; không skip/xfail.
Ruff check PASS; format PASS (75 file); OpenAPI snapshot khớp app; compileall và diff check PASS.
Warnings là deprecation của Starlette/httpx và Alembic `path_separator`, không phải test thất bại.

| Case/phạm vi | Expected | Actual | Kết quả |
|---|---|---|---|
| QA-ENV-01/02 phần migration | Dựng DB trống, chạy migrate lần hai no-op | Qua đủ 0001→0003, lần hai không chạy lại revision | PASS |
| Seed hỗ trợ CP1 | Nạp demo, login admin; seed lại không thay đổi khách hàng/số dư | 10 customers, 13 accounts, login ADMIN thành công; seed lại REJECTED | PASS |
| QA-AUTH-01 | Register 201, đúng 1 tỷ và CASH account | Kiểm tra trực tiếp Decimal trong PostgreSQL | PASS |
| QA-AUTH-02 phần server | Thiếu trường/đầu vào sai không tạo user | 422, không có customer/account mới | PASS |
| QA-AUTH-03 | Email/SĐT trùng, kể cả đồng thời, trả 409 | Ép 2 request cùng vượt pre-check; chỉ 1 customer/account và 1 tỷ | PASS |
| QA-AUTH-04 | Sai password/email không tồn tại trả 401 chung | Status/body giống nhau, không token | PASS |
| QA-AUTH-05/06 phần server | Refresh hợp lệ, token hết hạn/sai bị từ chối | Đúng type, lifetime, thiếu claim, claim sai; user đã xóa/khóa không refresh được | PASS |
| QA-AUTH-07 | Không dùng refresh làm access hoặc ngược lại | 401 | PASS |
| Ownership accounts | Hai user không nhận tài khoản của nhau | JWT là nguồn định danh; query customer_id không đổi chủ dữ liệu | PASS |
| Rollback đăng ký | Lỗi sau insert customer không để user/account dở dang | Không còn customer/account sau lỗi giả lập | PASS |
| Trùng số tài khoản sinh ở server | Retry transaction mới có giới hạn, không cấp tiền dư | Retry thành công hoặc 503 sau giới hạn, số dư/số bản ghi đúng | PASS |
| Hồi quy Admin | Xác thực/phân quyền/CRUD có sẵn tiếp tục chạy | 14 test Admin qua với error envelope đã cập nhật | PASS |

Test CP1 nằm tại `backend/tests/unit/test_auth_checkpoint.py` và
`backend/tests/integration/test_auth_checkpoint_postgres.py`.
Integration tự tạo/drop database ngẫu nhiên `stockmate_cp1_test_*` trong fixture;
không chạy TRUNCATE/DROP trên database do người dùng cung cấp.

## Thử qua server HTTP thật

Uvicorn chạy tại `127.0.0.1:18004`, trỏ tới DB thử nghiệm trống đã migrate.
Client dùng `urllib.request`, không override dependency:

```text
health/live 200; health/ready 200
register 201 → login 200 → me 200 → accounts 200 (đúng 1 CASH account)
access hết hạn 401 TOKEN_EXPIRED → refresh 200 → gọi lại accounts 200
refresh-as-access 401 UNAUTHORIZED; register trùng 409 DUPLICATE_EMAIL
```

Sau khi tắt PostgreSQL thử nghiệm, gọi lại server đang chạy:

```text
/health/live 200 PASS
/health/ready 503 DATABASE_UNAVAILABLE PASS
```

Response khi DB tắt không có URL/password/chi tiết lỗi kết nối.
Uvicorn và PostgreSQL thử nghiệm đã dừng sau khi kiểm tra.

## Sửa tối thiểu để dựng được môi trường

- Bỏ check `role` khỏi schema 0001 vì cột chưa tồn tại ở revision này;
  migration 0002 đã tạo cột và check tương ứng. Đã xác nhận lỗi gốc `UndefinedColumn: role`
  trên DB trống trước sửa, sau sửa migrate đầy đủ thành công.
- Seed thêm cột `role` và placeholder thứ 9 khớp tuple dữ liệu;
  trước sửa seed lỗi `8 placeholders but 9 parameters`, sau sửa seed và login demo thành công.

## Còn chờ bàn giao

- Sơn nối Flutter datasource, lưu access/refresh, dùng một refresh chung khi request đồng thời,
  retry tối đa một lần và xóa phiên khi refresh lỗi. Hiện mobile vẫn mock.
- Châu/Sơn xác nhận đăng ký → đăng nhập → chọn đúng tài khoản trên emulator/máy thật.
- QA-OWN-01 cho assets/portfolio/orders/transactions và phần UI của QA-AUTH-02/05/06
  chưa thuộc bằng chứng CP1 này; chưa ghi PASS cho các luồng chưa chạy.
- Môi trường kiểm thử là PostgreSQL 18/Python 3.14; chưa chạy lại trên PostgreSQL 16/Python 3.13.
- Workflow `checks` đã bổ sung job PostgreSQL 16/Python 3.13 chạy migration, seed,
  toàn bộ pytest và kiểm tra OpenAPI; chạy khi push `main`/`traidep` hoặc mở PR.
  Kết quả CI từ xa được theo dõi tại GitHub Actions, riêng với bằng chứng local ở trên.

Trạng thái TV4: **Chờ bàn giao**; chặng 1 toàn nhóm chưa được đánh dấu Xong.
