# Báo cáo Thiết lập Môi trường (Environment Setup)

Case: QA-ENV-01
Môi trường: Windows, Docker postgres:16-alpine, migration head 0005
Dữ liệu đầu vào: alembic upgrade head -> seed_demo.py
Expected: DB dựng từ trống, seed đủ dữ liệu
Actual: 10 customers / 90 stocks / 13 accounts / 58 orders / 46 transactions
Trạng thái: PASS (ghi số mã 90 lệch ACCEPTANCE 83)

Case: QA-ENV-02
Môi trường: Windows, Docker postgres:16-alpine
Dữ liệu đầu vào: alembic upgrade head -> seed_demo.py (chạy lần 2)
Expected: alembic không chạy thêm migration, seed_demo báo REJECTED
Actual: Migration giữ nguyên, seed_demo in REJECTED do DB đã có dữ liệu
Trạng thái: PASS