# TV1 — Phuoc: DB, môi trường và thứ tự tích hợp

Mở [START_HERE](../START_HERE.md), sau đó [DATABASE_WORKFLOW](../DATABASE_WORKFLOW.md).
Tra đủ file bằng `python scripts/check_preparation.py --owner TV1` từ repo gốc.

## ENV-01 — Dựng môi trường chung, làm đầu tiên

**Input:** SQL prototype gốc, BUSINESS_RULES và các file TODO. Chưa có Compose/migration/seed chạy được.

1. Theo SETUP C: tự viết Compose/Dockerfile, cấu hình Alembic, revision/SQL đầu tiên và seed an toàn.
2. Tự test migrate/seed DB mới và seed lần hai từ chối; LB viết health để cùng kiểm tra live/ready sau.
3. Kiểm tra email demo tồn tại; hash phải verify được với Matkhau@123, phối hợp LB khi auth đã được viết.
4. Ghi log và version vào `docs/qa/environment.md`; bàn giao host/port/database, không gửi SECRET_KEY vào repo.
5. Tự thêm migration/seed/DB tests vào CI khi implementation đã có; bổ sung GitHub username thật nếu nhóm muốn CODEOWNERS/branch protection.

**File sửa:** compose.yaml, backend/Dockerfile, backend/alembic*, backend/scripts/seed_demo.py,
.github/workflows/checks.yml, docs/SETUP.md, docs/DATABASE_WORKFLOW.md.

**Xong khi:** Châu/LB dựng lại được từ DB trống và API ready 200. Seed/migration không phá DB cũ.

## TR-01 — Schema cho engine, làm cùng Tuệ

**Input:** BUSINESS_RULES; test case TR-01 của Tuệ. Chưa cần Flutter đặt lệnh.

1. Cùng Tuệ liệt kê cột/constraint cần thêm: client_order_id, reserve, blocked_quantity, settlement lots.
2. Cùng Tuệ chốt invariant trong revision đầu tiên hoặc revision kế tiếp; thiết kế backfill dữ liệu nếu cần.
3. Viết routine phong tỏa/hủy/apply fill theo CASH-01/SHARE-01; thống nhất Tuệ đưa SQL, Phuoc tích hợp migration.
4. Viết giá trần/sàn đúng vùng chuyển bước giá; chỉ đóng băng revision sau khi nhóm phát hành thật.
5. Test upgrade từ DB trống và DB seed; bàn giao chính xác tên routine + params + lỗi cho Tuệ.

**File sửa:** backend/alembic/versions/, SQL tương ứng do nhóm tự viết;
data/postgres/03–07 nếu schema đích ảnh hưởng seed. Không chạy lại 00_run_all vào DB nhóm.

**Xong khi:** QA-ORD-01/03/04 và QA-SET-02 có nền schema, không âm hoặc lệch quantity.

## ENV-02 — Build demo sau G3

1. Sơn/Me xác nhận app chạy API thật trên emulator.
2. Châu chạy kịch bản ngoài giờ/internet tắt; chuẩn bị DB demo riêng để không đụng dữ liệu nhóm.
3. Theo dõi debug HTTP vs release HTTPS; cấu hình release endpoint phù hợp trước build APK demo.
4. Build Android; ghi command, commit SHA và vị trí APK trong hướng dẫn deploy.
5. Bảo đảm CI chạy ở PR; không đợi đến buổi demo mới kiểm tra build.

**File sửa:** mobile/android, mobile/ios, mobile/web, CI, docs/qa/demo.md, docs/WORK_BOARD.md (phối hợp Châu).

## Khi review PR

- DB có migration, backfill và test; không sửa trực tiếp DB nhóm ngoài migration.
- Contract đổi có snapshot/examples/model client tương ứng.
- Một PR một task hoặc phần task nhỏ; không gộp UI mới với thay đổi schema không liên quan.
- Không tự kéo timeline từ PLAN cũ; chốt mốc với nhóm và điền WORK_BOARD.

**PR đầu tiên:** `codex/ENV-01-environment`; đính kèm ready output + migration/seed log.
**Bàn giao:** LB nhận kết nối; Tuệ nhận schema/routines; Châu nhận kịch bản dựng lại.
