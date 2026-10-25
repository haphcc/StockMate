# Trạng thái kiểm tra sau khi gỡ implementation bổ sung

Theo yêu cầu nhóm: giữ khung, hướng dẫn, phân công và code gốc; phần implementation do
bước chuẩn bị thêm đã đưa về TODO. Đây không phải nghiệm thu tính năng.

| Phần | Trạng thái |
|---|---|
| Backend Python | File TODO; chưa có app/health/schema/DB session thực thi |
| Alembic/SQL/seed mới | TODO; không tạo database hoặc dữ liệu |
| SQL gốc data/postgres | Giữ nguyên so với commit trước bước chuẩn bị |
| Flutter gốc | Giữ nguyên code/test đã có; khôi phục cấu hình và widget đã sửa trong bước CI |
| OpenAPI snapshot | Đã gỡ; LB tự viết exporter và sinh lại khi có app/schema |
| Dockerfile/Compose | TODO; chưa khởi chạy được |
| Tests backend bổ sung | TODO; chưa có test nghiệp vụ thực thi |
| CI tự động | Chỉ kiểm tra khung/tài liệu/ownership, lint/format/cú pháp Python |
| Flutter CI | Chạy thủ công khi chọn run_mobile_checks; lỗi lint gốc thuộc FE-01 |

Kết quả 39 test backend/Flutter xanh trước đây thuộc implementation đã gỡ,
không còn dùng để khẳng định trạng thái hiện tại. Nhóm tự bổ sung bằng chứng khi hoàn thành task.

Lệnh kiểm tra hiện dùng: `python scripts/check_preparation.py`, Ruff check/format cho backend.
Kết quả chạy cụ thể xem job preparation trong GitHub Actions của commit tương ứng.
