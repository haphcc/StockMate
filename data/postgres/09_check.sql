-- =====================================================================
-- File 09: Cau truy van kiem tra tinh dung dan cua du lieu + vi du API
-- Chay sau khi nap xong. Tat ca cac muc "KIEM TRA" phai tra ve 0 dong.
-- =====================================================================

\echo '--- KIEM TRA 1: so du tien am (phai 0 dong) ---'
SELECT account_number, cash_balance FROM investment_accounts WHERE cash_balance < 0;

\echo '--- KIEM TRA 2: danh muc lech voi lich su khop lenh (phai 0 dong) ---'
SELECT p.account_id, p.stock_id, p.quantity AS qty_portfolio, t.qty AS qty_transactions
  FROM portfolios p
  JOIN (SELECT account_id, stock_id,
               SUM(CASE WHEN transaction_type = 'BUY' THEN quantity ELSE -quantity END) AS qty
          FROM transactions GROUP BY account_id, stock_id) t
    ON t.account_id = p.account_id AND t.stock_id = p.stock_id
 WHERE p.quantity <> t.qty;

\echo '--- KIEM TRA 3: gia khop nam ngoai bien do tran/san (phai 0 dong) ---'
SELECT stock_symbol, current_price, floor_price, ceiling_price
  FROM stocks
 WHERE current_price > ceiling_price OR current_price < floor_price;

\echo '--- KIEM TRA 4: tong tai san khong khop (phai 0 dong) ---'
SELECT a.account_number, a.total_asset_value, v.total_asset_value AS recomputed
  FROM investment_accounts a
  JOIN v_account_summary v ON v.account_id = a.account_id
 WHERE ABS(a.total_asset_value - v.total_asset_value) > 1;

-- ---------------------------------------------------------------------
-- VI DU TRUY VAN CHO API (FastAPI)
-- ---------------------------------------------------------------------

-- Bang gia HOSE, sap theo thanh khoan
-- GET /api/market/board?exchange=HOSE
SELECT stock_symbol, company_name, reference_price, ceiling_price, floor_price,
       current_price, change_percent, price_state, total_volume
  FROM v_market_board
 WHERE exchange = 'HOSE'
 ORDER BY total_volume DESC
 LIMIT 20;

-- Danh muc cua mot tai khoan
-- GET /api/accounts/{account_id}/portfolio
SELECT stock_symbol, quantity, available_quantity, average_price, market_price,
       current_value, profit_loss, profit_loss_percent
  FROM v_portfolio_detail
 WHERE account_number = '068C100009'
 ORDER BY current_value DESC;

-- Tong quan tai san cua khach hang
-- GET /api/customers/{customer_id}/assets
SELECT account_number, account_type, cash_balance, blocked_balance, stock_value,
       total_asset_value, total_profit_loss, profit_loss_percent
  FROM v_account_summary
 WHERE email = 'cuong.le@gmail.com';

-- So lenh dang cho khop
-- GET /api/accounts/{account_id}/orders?status=PENDING
SELECT order_id, stock_symbol, order_type, order_kind, quantity, filled_quantity,
       order_price, status, order_date
  FROM v_order_book
 WHERE status IN ('PENDING','PARTIAL')
 ORDER BY order_date DESC;

-- Du lieu ve bieu do nen 30 phien gan nhat cua FPT
-- GET /api/stocks/FPT/chart?range=1M
SELECT h.recorded_date, h.open_price, h.highest_price, h.lowest_price,
       h.close_price, h.trading_volume
  FROM stock_price_history h
  JOIN stocks s ON s.stock_id = h.stock_id
 WHERE s.stock_symbol = 'FPT'
 ORDER BY h.recorded_date DESC
 LIMIT 30;

-- Thong bao chua doc
-- GET /api/customers/{customer_id}/notifications?unread=true
SELECT n.title, n.notification_type, n.created_at
  FROM notifications n
  JOIN customers c ON c.customer_id = n.customer_id
 WHERE c.email = 'an.nguyen@gmail.com' AND n.is_read = FALSE
 ORDER BY n.created_at DESC;

-- Top lai / lo toan he thong
SELECT full_name, account_number, total_asset_value, total_profit_loss, profit_loss_percent
  FROM v_account_summary
 ORDER BY total_profit_loss DESC;
