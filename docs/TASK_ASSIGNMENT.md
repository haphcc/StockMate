# Phân công 6 thành viên

Me là tên riêng của **TV3**, một thành viên khác với người yêu cầu chuẩn bị repo.
Thứ tự làm chung nằm ở [PLAN](PLAN.md).

| Người | Làm gì | File/thư mục chính | Bàn giao cho |
|---|---|---|---|
| Phuoc — TV1 | Database, migration/seed, Docker, CI, APK, backend nạp tiền payOS, Backend Quản trị Admin | data/postgres/, backend/alembic/, backend/scripts/seed_demo.py, backend/app/api/v1/endpoints/payments.py, backend/app/api/v1/endpoints/admin/, backend/Dockerfile, compose.yaml, .github/workflows/, mobile/android/ và ios/ | LB/Tuệ nhận DB; Sơn nhận API nạp tiền; Châu nhận API Admin và APK |
| Sơn — TV2 | Flutter chung; auth, dashboard, portfolio, nạp tiền payOS | mobile/lib/core/, providers/, features/auth/, home/, portfolio/; data/models/ và repositories/ phần auth/account/portfolio/deposit | Me nhận network/router/helper; Châu nhận luồng đăng nhập/tài sản |
| Me — TV3 | Bảng giá/chi tiết/biểu đồ, watchlist, đặt lệnh, lịch sử, thông báo | mobile/lib/features/market/, watchlist/, order/, transaction/, notification/; models/datasources/repositories liên quan | Sơn nhận màn hình để gắn app; Châu nhận luồng thị trường/giao dịch |
| LB — TV4 | FastAPI chung, auth, accounts, assets, market, watchlist | backend/app/main.py, core/, db/, api/, models/, schemas/, crud/, services/ phần mình | Sơn/Me nhận API; Tuệ nhận xác thực và DB session |
| Tuệ — TV5 | Mua/bán, giữ tiền/cổ phiếu, khớp/hủy, T+2, thông báo | backend/app/ phần orders/transactions/notifications/settlement; backend/scripts/settle_shares.py; SQL phối hợp Phuoc | Me nhận API giao dịch; Châu nhận tình huống test |
| Châu — TV6 | Test, QA/QC, báo cáo/slide, Frontend Tab Quản trị Admin (ẩn trên mobile) | backend/tests/, mobile/test/, mobile/integration_test/, mobile/lib/features/admin/, docs/qa/, WORK_BOARD.md | Báo lỗi cho đúng người; nhận API Admin từ Phuoc; hoàn thiện giao diện quản trị |

## Cách phối hợp

- Phuoc giữ migration; Tuệ góp luật/SQL, LB kiểm tra mapping.
- Sơn giữ router/network/model dùng chung; Me (TV3) trao đổi trước khi sửa các file này.
- LB và Tuệ chia endpoint/model/service theo chức năng; mỗi người viết test cho phần mình, Châu kiểm tra tích hợp.
- Làm một việc trên một nhánh; gửi PR để người nhận thử rồi cập nhật [WORK_BOARD](WORK_BOARD.md).

Muốn tra chính xác từng file: [FILE_OWNERS](FILE_OWNERS.md), hoặc
`python scripts/check_preparation.py --owner TV3` (đổi số theo thành viên).
Hướng dẫn từng người nằm trong [START_HERE](START_HERE.md).

## Báo cáo

Mỗi người viết phần đã làm; Châu ghép thành báo cáo và slide.

| Người | Phần viết |
|---|---|
| Phuoc | ERD, thiết kế CSDL khái niệm, môi trường/triển khai, tối ưu DB, backend nạp tiền payOS |
| Sơn | Cài Flutter, kiến trúc giao diện/state, nạp tiền VietQR payOS, hướng dẫn sử dụng |
| Me (TV3) | Activity đăng ký/đăng nhập và mua/bán, UI thị trường, ảnh màn hình |
| LB | CSDL logic, Class Diagram, kiến trúc/API backend; tài liệu vnstock khi làm mở rộng |
| Tuệ | CSDL vật lý, Sequence auth/khớp lệnh, nghiệp vụ/routine và T+2 |
| Châu | Use Case, kiến trúc Frontend Tab Admin ẩn trên mobile, kết quả kiểm thử, báo cáo tổng hợp và slide |
