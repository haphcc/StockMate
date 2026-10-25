# Bảng việc thực thi

Châu cập nhật trạng thái theo bằng chứng; Phuoc chốt thứ tự/ngày với nhóm.
`PREPARED` = có khung/tài liệu, `TODO` = chưa triển khai, `DOING`, `BLOCKED`, `DONE` = có nghiệm thu.
Ngày bắt đầu và deadline do nhóm điền; chưa giả định đã bắt đầu lại sprint vào ngày nào.

| ID | Chủ | Việc | Chờ | Bàn giao/DoD | Trạng thái |
|---|---|---|---|---|---|
| PREP-01 | Phuoc/LB/Châu | Scope, rules, contract, structure, guide | — | Link đầy đủ; TODO có chủ; không có implementation bổ sung | PREPARED |
| ENV-01 | Phuoc | Tự viết Docker/migration/seed; cùng LB kiểm tra health | — | QA-ENV-01/02/03 + log Châu xác nhận | TODO |
| FE-01 | Sơn | Model tiền và form auth đúng contract | — | Fixture parse chính xác, form validate, test xanh | TODO |
| FE-03 | Me | Board/detail/chart từ fixture rồi API | FE-01 helper; API cần BE-02/03 | QA-MKT-01/02/03 | TODO |
| BE-01 | LB | Viết app/config/schema/health/session, auth + đăng ký atomic | ENV-01 | QA-AUTH-01–07 | TODO |
| BE-02 | LB | Account/asset và board | BE-01 | Auth → account → board thật | TODO |
| QA-01 | Châu | Setup và contract evidence | ENV-01 cho DB | G0, ghi environment.md | TODO |
| FE-02 | Sơn | API repositories, JWT/refresh/account | FE-01 + BE-01/02 | G1 trên emulator, logout/restart đúng | TODO |
| TR-01 | Tuệ + Phuoc | Test luật + migration invariant | — | Migration được review, routine interface, backfill | TODO |
| BE-03 | LB | Portfolio hoàn chỉnh/chart/watchlist | BE-02; portfolio đợi TR-01 | G2 API | TODO |
| FE-04 | Sơn + Me | Asset/portfolio/watchlist thật | FE-02 + BE-03 | QA-ACC/MKT liên quan | TODO |
| TR-02 | Tuệ | Place/match/cancel/history/notifications | BE-01 + TR-01 | QA-ORD-01–09, QA-NOT-01 | TODO |
| TR-03 | Tuệ + Phuoc | T+2 từng lot | TR-01/02 | QA-SET-01/02/03 | TODO |
| FE-05 | Me | UI trading/history/notification thật | FE-02 + TR-02 | G3 trên app + invalidation | TODO |
| QA-02 | Châu | E2E auth/market/ownership | G1/G2 từng phần | Log/ảnh app thật, case pass | TODO |
| QA-03 | Châu | Regression tài chính + demo/report | TR-02/03 + FE-05 | G4, bugs retest, demo ngoài giờ | TODO |
| ENV-02 | Phuoc | Build APK và môi trường demo | G3 + QA-03 | APK có commit/version, chạy máy thật | TODO |
| BE-04 | LB | vnstock live worker | Sau G4 | Quote mapping/freshness/rate limit đã test | DEFERRED |

## Chia việc buổi đầu để không ngồi chờ

- Phuoc chạy ENV-01; LB đọc/viết mapping và security BE-01, kiểm tra DB khi ENV-01 bàn giao.
- Sơn làm FE-01 bằng fixture; Me dựng market screen với fixture cùng helper thống nhất.
- Tuệ viết expected test và SQL proposal TR-01; phối hợp Phuoc sau ENV-01.
- Châu kiểm tra setup/contracts/links và soạn case; chưa đợi sprint cuối mới kiểm tra.

## Điều kiện kéo một việc sang DONE

Có PR/commit, lệnh test và kết quả; người nhận bàn giao dùng được; contract/migration/fixture/docs cùng cập nhật.
Chưa có code hoặc chưa có runtime để chạy thì ghi NOT RUN/BLOCKED trong evidence, không đánh dấu DONE.
Các kết quả kiểm tra của bộ chuẩn bị xem [qa/PREPARATION_CHECK.md](qa/PREPARATION_CHECK.md).
