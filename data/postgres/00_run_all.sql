-- =====================================================================
-- Chay toan bo: tao schema + nap du lieu mau
--   psql -h localhost -U postgres -d stock_exchange -f 00_run_all.sql
-- Luu y: cac file duoi day chay theo dung thu tu, KHONG doi thu tu.
-- =====================================================================
\set ON_ERROR_STOP on

\echo '>> 01 schema'
\i 01_schema.sql
\echo '>> 02 functions & triggers'
\i 02_functions_triggers.sql
\echo '>> 03 stocks'
\i 03_seed_stocks.sql
\echo '>> 04 customers / accounts / watchlists'
\i 04_seed_customers.sql
\echo '>> 05 orders & transactions'
\i 05_seed_trading.sql
\echo '>> 06 price history'
\i 06_seed_price_history.sql
\echo '>> 07 notifications'
\i 07_seed_notifications.sql
\echo '>> 08 views'
\i 08_views.sql
\echo '>> DONE'

SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'investment_accounts', COUNT(*) FROM investment_accounts
UNION ALL SELECT 'stocks',              COUNT(*) FROM stocks
UNION ALL SELECT 'portfolios',          COUNT(*) FROM portfolios
UNION ALL SELECT 'stock_orders',        COUNT(*) FROM stock_orders
UNION ALL SELECT 'transactions',        COUNT(*) FROM transactions
UNION ALL SELECT 'watchlists',          COUNT(*) FROM watchlists
UNION ALL SELECT 'stock_price_history', COUNT(*) FROM stock_price_history
UNION ALL SELECT 'notifications',       COUNT(*) FROM notifications;
