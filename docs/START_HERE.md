# Bắt đầu làm StockMate — đọc file này trước

Bộ hướng dẫn làm việc cho 6 thành viên, lập ngày 25/10/2026.
Phạm vi bản đầu nằm trong [MVP_SCOPE.md](MVP_SCOPE.md); kế hoạch cũ là định hướng mở rộng.

## 1. Đọc theo đúng thứ tự

1. [MVP_SCOPE.md](MVP_SCOPE.md): nhóm phải giao gì, phần nào để sau.
2. [BUSINESS_RULES.md](BUSINESS_RULES.md): đặt/khớp/hủy lệnh phải hoạt động thế nào.
3. [API_CONTRACT.md](API_CONTRACT.md): request/response, token, tiền và mã lỗi.
4. [SETUP.md](SETUP.md): cài và chạy từng bước; thấy kết quả nào là đúng.
5. [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md): vị trí từng file, hướng phụ thuộc.
6. [FILE_OWNERS.md](FILE_OWNERS.md): ai phụ trách file nào, cách sửa file chung.
7. Hướng dẫn cá nhân ở bảng dưới; làm theo task ID từ trên xuống.

## 2. Mỗi người mở đúng file của mình

| Người | Mở ngay | Việc đầu tiên | Bàn giao cho |
|---|---|---|---|
| TV1 — Phuoc | [TV1_PHUOC.md](team/TV1_PHUOC.md) | ENV-01: dựng DB mới, migrate, seed, ghi bằng chứng | LB, Tuệ, Châu |
| TV2 — Sơn | [TV2_SON.md](team/TV2_SON.md) | FE-01: sửa model tiền và form đăng ký theo contract | LB, Me, Châu |
| TV3 — Me | [TV3_ME.md](team/TV3_ME.md) | FE-03: dựng bảng giá/chi tiết bằng JSON mẫu | Sơn, Châu |
| TV4 — LB | [TV4_LB.md](team/TV4_LB.md) | BE-01: auth + khách hàng/tài khoản trong DB | Sơn, Tuệ, Châu |
| TV5 — Tuệ | [TV5_TUE.md](team/TV5_TUE.md) | TR-01: đặc tả test phong tỏa và khớp lệnh | Phuoc, LB, Me |
| TV6 — Châu | [TV6_CHAU.md](team/TV6_CHAU.md) | QA-01: kiểm tra setup và chạy contract tests | Cả nhóm |

## 3. Mốc phải qua theo thứ tự

| Mốc | Kết quả bắt buộc | Phụ thuộc |
|---|---|---|
| G0 — môi trường | DB mới migrate/seed được; API `/health/live` 200, `/health/ready` 200; backend tests xanh | ENV-01 |
| G1 — luồng thật đầu tiên | Đăng ký → login → chọn CASH account → bảng giá từ API trên Flutter | BE-01/02, FE-01/02/03, QA-02 |
| G2 — tài sản/thị trường | Đổi account, danh mục, chart, watchlist; refresh từ dữ liệu thật | G1, BE-03, FE-04 |
| G3 — giao dịch | Mua → phong tỏa → khớp/hủy → số dư/danh mục đúng → T+2 từng đợt | G1, TR-01/02/03, FE-05 |
| G4 — demo | E2E, APK, dữ liệu demo ổn định, báo cáo và kịch bản | G2 + G3 + QA-03 |

Mốc là điều kiện nghiệm thu, không phải lời khẳng định đã xong. Đánh dấu trạng thái thực tế trong
[WORK_BOARD.md](WORK_BOARD.md). Nhóm tự điền ngày bắt đầu/deadline vào đó; không tái dùng mốc 04/10 cũ.

## 4. Một buổi làm việc mẫu

1. `git status` để biết thay đổi đang có. Cất thay đổi bằng commit phù hợp trước khi chuyển nhánh.
2. `git switch main`, `git pull --ff-only`, rồi `git switch -c codex/BE-01-auth` (đổi ID theo việc).
3. Mở hướng dẫn cá nhân → đọc input → sửa đúng nhóm file → chạy kiểm tra được ghi trong task.
4. Commit các file đã chọn bằng đường dẫn cụ thể; tránh gộp file người khác vào commit.
5. Push nhánh, tạo PR: ghi task ID, thay đổi, lệnh đã chạy, ảnh/log và phần chưa làm.
6. Nhờ người nhận bàn giao kiểm tra. Thay đổi DB/contract/file chung phải có chủ file cùng review.
7. Châu cập nhật WORK_BOARD theo bằng chứng; không đánh dấu xong chỉ vì UI có thể bấm.

Các lệnh git ở đây là hướng dẫn cho nhóm; bộ chuẩn bị không tự push hay tạo PR.

## 5. Đang chạy được gì, còn phải viết gì

- Có khung API, health checks, lỗi thống nhất, schema và Swagger/OpenAPI.
- Có Docker Compose, migration baseline không reset DB, seed một lần và hash demo thật.
- Có test nền, JSON mẫu, cây file và người phụ trách.
- Endpoint nghiệp vụ hiện trả `501 NOT_IMPLEMENTED`; có token bất kỳ cũng không được truy cập dữ liệu.
- Flutter mặc định vẫn dùng mock. `USE_MOCK=false` chỉ dùng sau khi FE-02 hoàn thành.
- File có nhãn `TODO(task-id)` là vị trí bàn giao, không phải tính năng đã triển khai.
- Trigger SQL baseline còn khoảng trống đã liệt kê trong [DATABASE_WORKFLOW.md](DATABASE_WORKFLOW.md).

## 6. Quy tắc khi các tài liệu khác nhau

Phạm vi: MVP_SCOPE → luật: BUSINESS_RULES → wire format: schema Python + `backend/openapi.json`.
PLAN/TASK_ASSIGNMENT giữ định hướng và lịch sử phân công. Thay đổi contract phải cập nhật schema,
JSON mẫu, tài liệu và snapshot trong cùng PR; LB chủ trì, Sơn/Me xác nhận phần client bị ảnh hưởng.
