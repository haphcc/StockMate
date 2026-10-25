# Bắt đầu làm StockMate — đọc file này trước

**Tên thành viên:** “Me” là tên gọi riêng của thành viên **TV3**, không phải đại từ “tôi” hay người yêu cầu chuẩn bị repo.

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
| TV2 — Sơn | [TV2_SON.md](team/TV2_SON.md) | FE-01: sửa model tiền và form đăng ký theo contract | LB, Me (TV3), Châu |
| TV3 — Me | [TV3_ME.md](team/TV3_ME.md) | FE-03: dựng bảng giá/chi tiết bằng JSON mẫu | Sơn, Châu |
| TV4 — LB | [TV4_LB.md](team/TV4_LB.md) | BE-01: auth + khách hàng/tài khoản trong DB | Sơn, Tuệ, Châu |
| TV5 — Tuệ | [TV5_TUE.md](team/TV5_TUE.md) | TR-01: đặc tả test phong tỏa và khớp lệnh | Phuoc, LB, Me (TV3) |
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

## 5. Giữ lại gì, nhóm phải tự viết gì

- Giữ UI/mock Flutter và SQL prototype gốc của nhóm.
- Giữ cây file, TODO có chủ, tài liệu phạm vi/luật/API và JSON ví dụ.
- Phần implementation bổ sung đã gỡ: backend, schema thực thi, migration/seed, Docker và tests mới đều là TODO.
- Chưa có API/health/Swagger hoặc endpoint 501 hoạt động; LB tự viết từ BE-01.
- Flutter gốc vẫn dùng useMock=true; Sơn tự thêm lựa chọn mock/API ở FE-02.
- CI tự động chỉ kiểm tra bộ khung; Phuoc/Châu thêm test tính năng sau khi nhóm tự triển khai.
- Việc DB xem [DATABASE_WORKFLOW.md](DATABASE_WORKFLOW.md).

## 6. Quy tắc khi các tài liệu khác nhau

Phạm vi: MVP_SCOPE → luật: BUSINESS_RULES → wire format đích: API_CONTRACT + JSON mẫu.
Schema Python và OpenAPI do LB tự viết/sinh sau; hiện chưa có snapshot.
PLAN/TASK_ASSIGNMENT giữ định hướng và lịch sử phân công. Thay đổi contract phải cập nhật schema,
JSON mẫu, tài liệu và snapshot trong cùng PR; LB chủ trì, Sơn/Me (TV3) xác nhận phần client bị ảnh hưởng.
