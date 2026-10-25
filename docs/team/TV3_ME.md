# TV3 — Me: thị trường, watchlist, giao dịch và thông báo

Tra file: `python scripts/check_preparation.py --owner TV3` từ repo gốc.
Đọc API_CONTRACT, BUSINESS_RULES và fixture; nhận helper tiền/network/router từ Sơn.

## FE-03 — Market board và stock detail, bắt đầu với fixture

1. Sửa StockModel parse string tiền bằng helper Sơn; thêm price_state/data_source/is_stale.
2. Làm CandleModel parse OHLCV và date; dữ liệu chart sort tăng theo ngày.
3. Viết market_provider theo exchange/q/page; debounce tìm kiếm, hủy request/provider không còn dùng.
4. Dựng MarketBoardScreen từ items của provider, không khai báo const stocks trong widget.
5. Filter/tìm kiếm/sort phải đổi dữ liệu thật; có loading/empty/error. Đúng 5 màu giá.
6. StockDetail hiển thị quote và chart 1M/3M/6M; ghi DEMO/giá cũ đúng metadata.
7. Dùng MarketRepository của Sơn; đề xuất thêm method detail/chart trong PR phối hợp,
   Sơn giữ file aggregate. Chỉ mock ở datasource/repository, không viết số cứng vào UI.
8. Sơn gắn route/board widget vào shell/dashboard sau khi bàn giao; không tự sửa router chung song song.

**File:** features/market/screens/{market_board,stock_detail}_screen.dart,
features/market/providers/market_provider.dart; data/models/{stock,candle}_model.dart.
**Đầu vào:** docs/contracts/examples.json; API market thật từ BE-02/03 để hoàn thành tích hợp.
**Xong khi:** QA-MKT-01/02/03 và refresh có dữ liệu từ repository; tap mã mở đúng detail.

## FE-04 — Watchlist sau BE-03

1. Điền watchlist_datasource/repository/provider; GET array, POST symbol, DELETE path symbol.
2. Một danh sách mặc định; thêm lặp không nhân đôi; xóa lặp vẫn ổn.
3. Hiển thị quote lồng trong `stock` theo WatchlistResponse (khác portfolio phẳng).
4. Sau thêm/xóa từ detail, invalidate watchlist để hai màn hình đồng nhất.

**File:** data/datasources/watchlist_datasource.dart; data/repositories/watchlist_repository.dart;
features/watchlist/*.
**Xong khi:** QA-MKT-02 với API thật; đăng xuất không còn watchlist user trước.

## FE-05 — Đặt/hủy và lịch sử, sau TR-02

1. Điền OrderModel/TransactionModel; request limit_price VND string, integer quantity và UUID.
2. PlaceOrderScreen nhận symbol/account từ route/state; bỏ MWG viết cứng và snackbar thành công giả.
3. Form có BUY/SELL, giá, quantity; kiểm tra band/tick/lot, hiển thị ước tính phí/thuế.
   Server vẫn quyết định validation/sức mua, client không tự cập nhật balance thật.
4. Tạo UUID một lần khi người dùng xác nhận ý định mới; disable nút lúc đang gửi;
   timeout/retry giữ UUID, không tạo UUID mới mỗi lần gọi repository.
5. Điền trading_datasource/repository/order_provider, sổ lệnh theo status và phân trang.
6. Hủy chờ API xác nhận; completed trả 409 thì refresh sổ lệnh; không xóa lệnh khỏi lịch sử.
7. Lịch sử giao dịch thể hiện gross/fee/tax/net và settlement_date; khác sổ lệnh.
8. Điền notification model/datasource/repository/provider/screen; list và mark-read, không push.
9. Phối hợp Sơn invalidate assets/portfolio/order/transaction/notification theo account sau thay đổi.
10. Dữ liệu lỗi/501 thì báo đúng; không biến lỗi thành thành công để demo.

**File:** features/order/*, features/transaction/*, features/notification/*;
data/models/{order,transaction,notification}_model.dart;
data/datasources/{trading,notification}_datasource.dart;
data/repositories/{trading,notification}_repository.dart.

**Xong khi:** QA-ORD-01/02/03/06 trên app, QA-UI-01, QA-NOT-01; không phải chỉ test bấm nút.

**PR đầu tiên:** `codex/FE-03-market-fixtures`.
**Bàn giao cho Sơn:** widget/route requirements; cho Châu: ảnh trạng thái + input symbol/account;
cho Tuệ: request payload thực tế và UUID được giữ khi retry.
