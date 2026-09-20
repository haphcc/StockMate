-- =====================================================================
-- File 08: VIEW phuc vu truc tiep cac man hinh cua app Flutter
-- =====================================================================

-- ---------------------------------------------------------------------
-- 8.1 Bang gia (Market board) - man hinh "Bảng giá"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_market_board AS
SELECT s.stock_id,
       s.stock_symbol,
       s.company_name,
       s.exchange,
       s.industry,
       s.reference_price,
       s.ceiling_price,
       s.floor_price,
       s.current_price,
       s.current_price - s.reference_price AS price_change,
       ROUND((s.current_price - s.reference_price) * 100.0
             / NULLIF(s.reference_price, 0), 2) AS change_percent,
       CASE
           WHEN s.current_price >= s.ceiling_price       THEN 'CEILING'
           WHEN s.current_price <= s.floor_price         THEN 'FLOOR'
           WHEN s.current_price >  s.reference_price     THEN 'UP'
           WHEN s.current_price <  s.reference_price     THEN 'DOWN'
           ELSE 'REFERENCE'
       END AS price_state,           -- dung de to mau tim/xanh/do/vang/xanh lam
       s.total_volume,
       s.listed_shares,
       s.listed_shares * s.current_price AS market_cap,
       s.status,
       s.updated_at
  FROM stocks s;

-- ---------------------------------------------------------------------
-- 8.2 Chi tiet danh muc - man hinh "Danh mục"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_portfolio_detail AS
SELECT p.portfolio_id,
       p.account_id,
       a.account_number,
       a.customer_id,
       s.stock_id,
       s.stock_symbol,
       s.company_name,
       s.exchange,
       p.quantity,
       p.available_quantity,
       p.quantity - p.available_quantity AS pending_quantity,   -- co phieu cho ve (T+)
       p.average_price,
       s.current_price                   AS market_price,
       p.quantity * p.average_price      AS cost_value,
       p.quantity * s.current_price      AS current_value,
       p.quantity * (s.current_price - p.average_price) AS profit_loss,
       ROUND((s.current_price - p.average_price) * 100.0
             / NULLIF(p.average_price, 0), 2) AS profit_loss_percent
  FROM portfolios p
  JOIN investment_accounts a ON a.account_id = p.account_id
  JOIN stocks s              ON s.stock_id   = p.stock_id
 WHERE p.quantity > 0;

-- ---------------------------------------------------------------------
-- 8.3 Tong quan tai khoan - man hinh "Tài sản"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_account_summary AS
SELECT a.account_id,
       a.account_number,
       a.account_type,
       a.status,
       c.customer_id,
       c.full_name,
       c.email,
       a.cash_balance,
       a.blocked_balance,
       COALESCE(pf.stock_value, 0)                           AS stock_value,
       a.cash_balance + a.blocked_balance
           + COALESCE(pf.stock_value, 0)                     AS total_asset_value,
       COALESCE(pf.total_cost, 0)                            AS total_cost,
       COALESCE(pf.profit_loss, 0)                           AS total_profit_loss,
       ROUND(COALESCE(pf.profit_loss, 0) * 100.0
             / NULLIF(pf.total_cost, 0), 2)                  AS profit_loss_percent,
       COALESCE(pf.symbol_count, 0)                          AS symbol_count
  FROM investment_accounts a
  JOIN customers c ON c.customer_id = a.customer_id
  LEFT JOIN (
        SELECT p.account_id,
               SUM(p.quantity * s.current_price)                     AS stock_value,
               SUM(p.quantity * p.average_price)                     AS total_cost,
               SUM(p.quantity * (s.current_price - p.average_price)) AS profit_loss,
               COUNT(*)                                              AS symbol_count
          FROM portfolios p
          JOIN stocks s ON s.stock_id = p.stock_id
         WHERE p.quantity > 0
         GROUP BY p.account_id
  ) pf ON pf.account_id = a.account_id;

-- ---------------------------------------------------------------------
-- 8.4 So lenh - man hinh "Sổ lệnh"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_book AS
SELECT o.order_id,
       o.account_id,
       a.account_number,
       a.customer_id,
       s.stock_symbol,
       s.exchange,
       o.order_type,
       o.order_kind,
       o.quantity,
       o.filled_quantity,
       o.quantity - o.filled_quantity AS remaining_quantity,
       o.order_price,
       o.quantity * o.order_price     AS order_value,
       o.status,
       o.reject_reason,
       o.order_date,
       o.matched_at
  FROM stock_orders o
  JOIN investment_accounts a ON a.account_id = o.account_id
  JOIN stocks s              ON s.stock_id   = o.stock_id;

-- ---------------------------------------------------------------------
-- 8.5 Lich su giao dich - man hinh "Lịch sử giao dịch"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_transaction_history AS
SELECT t.transaction_id,
       t.account_id,
       a.account_number,
       a.customer_id,
       s.stock_symbol,
       s.company_name,
       t.transaction_type,
       t.quantity,
       t.price,
       t.total_amount,
       t.transaction_fee,
       t.tax_amount,
       t.net_amount,
       t.transaction_date,
       t.settlement_date
  FROM transactions t
  JOIN investment_accounts a ON a.account_id = t.account_id
  JOIN stocks s              ON s.stock_id   = t.stock_id;

-- ---------------------------------------------------------------------
-- 8.6 Danh muc quan tam kem gia thi truong - man hinh "Quan tâm"
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_watchlist_detail AS
SELECT w.watchlist_id,
       w.customer_id,
       w.list_name,
       s.stock_id,
       s.stock_symbol,
       s.company_name,
       s.exchange,
       s.reference_price,
       s.current_price,
       s.current_price - s.reference_price AS price_change,
       ROUND((s.current_price - s.reference_price) * 100.0
             / NULLIF(s.reference_price, 0), 2) AS change_percent,
       w.target_price,
       w.note,
       w.created_at
  FROM watchlists w
  JOIN stocks s ON s.stock_id = w.stock_id;
