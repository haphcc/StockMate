-- =====================================================================
-- File 05: LENH DAT (stock_orders) + KHOP LENH (transactions)
-- Trigger fn_apply_transaction() se tu dong:
--    - sinh/cap nhat portfolios (so luong + gia von binh quan)
--    - tru/cong cash_balance cua tai khoan
--    - chuyen trang thai lenh sang PARTIAL / COMPLETED
-- Bieu phi ap dung: phi giao dich 0,15% gia tri khop
--                   thue TNCN 0,1% gia tri ban (chi khi BAN)
-- Ngay thanh toan: T+2
-- =====================================================================

DO $$
DECLARE
    r           RECORD;
    v_order_id  BIGINT;
    v_total     NUMERIC(20,2);
    v_fee       NUMERIC(20,2);
    v_tax       NUMERIC(20,2);
    v_net       NUMERIC(20,2);
    v_order_dt  TIMESTAMPTZ;
    v_match_dt  TIMESTAMPTZ;
BEGIN
    FOR r IN
        SELECT a.account_id, s.stock_id, v.*
        FROM (VALUES
            -- acc_no,      symbol, type,  kind, qty,   price,  days_ago, final_status, reject_reason
            ('068C100009','VCB' ,'BUY' ,'LO' , 5000,  55000::NUMERIC, 400,'COMPLETED',NULL),
            ('068C100009','ACV' ,'BUY' ,'LO' , 2000,  78000::NUMERIC, 350,'COMPLETED',NULL),
            ('068C100005','HPG' ,'BUY' ,'LO' ,10000,  23000::NUMERIC, 300,'COMPLETED',NULL),
            ('068C100004','VIC' ,'BUY' ,'LO' , 1000,  88000::NUMERIC, 250,'COMPLETED',NULL),
            ('068C100011','HPG' ,'BUY' ,'LO' , 4000,  24500::NUMERIC, 220,'COMPLETED',NULL),
            ('068C100004','VHM' ,'BUY' ,'LO' , 1500,  72000::NUMERIC, 200,'COMPLETED',NULL),
            ('068C100009','DGC' ,'BUY' ,'LO' , 1500,  88000::NUMERIC, 200,'COMPLETED',NULL),
            ('068C100001','FPT' ,'BUY' ,'LO' ,  500,  82000::NUMERIC, 200,'COMPLETED',NULL),
            ('068C100003','VNM' ,'BUY' ,'LO' , 1000,  66000::NUMERIC, 180,'COMPLETED',NULL),
            ('068C100007','GAS' ,'BUY' ,'LO' , 1000,  72000::NUMERIC, 160,'COMPLETED',NULL),
            ('068C100005','MWG' ,'BUY' ,'LO' , 3000,  55000::NUMERIC, 150,'COMPLETED',NULL),
            ('068C100001','HPG' ,'BUY' ,'LO' , 2000,  25000::NUMERIC, 150,'COMPLETED',NULL),
            ('068C100011','KBC' ,'BUY' ,'LO' , 3000,  25000::NUMERIC, 140,'COMPLETED',NULL),
            ('068C100002','SSI' ,'BUY' ,'LO' , 3000,  24000::NUMERIC, 120,'COMPLETED',NULL),
            ('068C100004','MSN' ,'BUY' ,'LO' ,  800,  68000::NUMERIC, 120,'COMPLETED',NULL),
            ('068C100007','BSR' ,'BUY' ,'LO' , 5000,  19000::NUMERIC, 110,'COMPLETED',NULL),
            ('068C100003','SAB' ,'BUY' ,'LO' ,  500,  52000::NUMERIC, 100,'COMPLETED',NULL),
            ('068C100009','VGI' ,'BUY' ,'LO' , 2000,  62000::NUMERIC, 100,'COMPLETED',NULL),
            ('068C100006','TCB' ,'BUY' ,'LO' , 2000,  22000::NUMERIC,  90,'COMPLETED',NULL),
            ('068C100011','IDC' ,'BUY' ,'LO' , 1500,  39000::NUMERIC,  90,'COMPLETED',NULL),
            ('068C100001','VCB' ,'BUY' ,'LO' ,  300,  58000::NUMERIC,  90,'COMPLETED',NULL),
            ('068C100010','SHB' ,'BUY' ,'LO' , 3000,  11000::NUMERIC,  80,'COMPLETED',NULL),
            ('068C100008','VIC' ,'BUY' ,'LO' ,  500,  91000::NUMERIC,  70,'COMPLETED',NULL),
            ('068C100002','VND' ,'BUY' ,'LO' , 5000,  15000::NUMERIC,  60,'COMPLETED',NULL),
            ('068C100004','DGC' ,'BUY' ,'LO' ,  500,  98000::NUMERIC,  60,'COMPLETED',NULL),
            ('068C100012','DXG' ,'BUY' ,'LO' , 2000,  18000::NUMERIC,  60,'CANCELLED',NULL),
            ('068C100007','PVS' ,'BUY' ,'LO' , 2000,  31000::NUMERIC,  50,'COMPLETED',NULL),
            ('068C100005','HPG' ,'SELL','LO' , 3000,  28000::NUMERIC,  45,'COMPLETED',NULL),
            ('068C100001','FPT' ,'BUY' ,'LO' ,  300,  95000::NUMERIC,  40,'COMPLETED',NULL),
            ('068C100006','MBB' ,'BUY' ,'LO' , 2000,  23000::NUMERIC,  40,'COMPLETED',NULL),
            ('068C100008','VHM' ,'BUY' ,'LO' ,  800,  76000::NUMERIC,  35,'COMPLETED',NULL),
            ('068C100003','MCH' ,'BUY' ,'LO' ,  300, 110000::NUMERIC,  30,'COMPLETED',NULL),
            ('068C100009','VGI' ,'SELL','LO' ,  500,  90000::NUMERIC,  30,'COMPLETED',NULL),
            ('068C100010','VIX' ,'BUY' ,'LO' , 2000,  12000::NUMERIC,  30,'COMPLETED',NULL),
            ('068C100004','VHM' ,'SELL','LO' ,  500,  79000::NUMERIC,  25,'COMPLETED',NULL),
            ('068C100011','KBC' ,'SELL','LO' , 1000,  28500::NUMERIC,  20,'COMPLETED',NULL),
            ('068C100001','HPG' ,'SELL','LO' , 1000,  28500::NUMERIC,  20,'COMPLETED',NULL),
            ('068C100005','FPT' ,'BUY' ,'LO' , 1000,  97000::NUMERIC,  15,'COMPLETED',NULL),
            ('068C100007','BSR' ,'SELL','LO' , 2000,  22000::NUMERIC,  12,'COMPLETED',NULL),
            ('068C100009','FPT' ,'BUY' ,'LO' , 1500,  99000::NUMERIC,  10,'COMPLETED',NULL),
            ('068C100002','SSI' ,'SELL','LO' , 1000,  27500::NUMERIC,  10,'COMPLETED',NULL),
            ('068C100008','VIC' ,'SELL','LO' ,  200,  96000::NUMERIC,   8,'COMPLETED',NULL),
            ('068C100006','TCB' ,'SELL','LO' ,  500,  25500::NUMERIC,   6,'COMPLETED',NULL),
            ('068C100011','GEX' ,'BUY' ,'LO' , 2000,  37000::NUMERIC,   5,'COMPLETED',NULL),
            ('068C100010','SHB' ,'SELL','LO' , 1000,  12200::NUMERIC,   4,'COMPLETED',NULL),
            ('068C100001','MWG' ,'BUY' ,'LO' ,  500,  63000::NUMERIC,   3,'COMPLETED',NULL),
            ('068C100007','PLX' ,'BUY' ,'LO' , 1000,  38000::NUMERIC,   3,'COMPLETED',NULL),
            -- Lenh con hieu luc / bi huy / bi tu choi
            ('068C100001','FPT' ,'SELL','LO' ,  200, 115000::NUMERIC,   2,'CANCELLED',NULL),
            ('068C100004','VIC' ,'SELL','LO' ,  300,  99000::NUMERIC,   2,'PENDING'  ,NULL),
            ('068C100002','SHS' ,'BUY' ,'LO' , 2000,  14000::NUMERIC,   2,'PENDING'  ,NULL),
            ('068C100006','ACB' ,'BUY' ,'LO' ,  500,  25000::NUMERIC,   2,'PENDING'  ,NULL),
            ('068C100008','VRE' ,'BUY' ,'LO' , 1000,  35000::NUMERIC,   1,'REJECTED' ,'Giá đặt vượt giá trần'),
            ('068C100010','TPB' ,'BUY' ,'LO' , 1000,  16000::NUMERIC,   1,'PENDING'  ,NULL),
            ('068C100013','VNM' ,'BUY' ,'LO' ,  200,  59000::NUMERIC,   1,'REJECTED' ,'Tài khoản chưa hoàn tất định danh eKYC'),
            ('068C100011','SZC' ,'BUY' ,'LO' , 1000,  39000::NUMERIC,   1,'PENDING'  ,NULL),
            ('068C100003','PNJ' ,'BUY' ,'LO' ,  200,  86000::NUMERIC,   1,'PENDING'  ,NULL),
            ('068C100005','VCB' ,'BUY' ,'MP' , 1000,      0::NUMERIC,   0,'PENDING'  ,NULL),
            ('068C100009','ACV' ,'SELL','LO' ,  500,  98000::NUMERIC,   0,'PENDING'  ,NULL)
        ) AS v(acc_no, symbol, otype, okind, qty, price, days_ago, final_status, reject_reason)
        JOIN investment_accounts a ON a.account_number = v.acc_no
        JOIN stocks             s ON s.stock_symbol   = v.symbol
        ORDER BY v.days_ago DESC, v.acc_no
    LOOP
        -- gio dat lenh: rai deu trong phien 09:15 - 14:30
        v_order_dt := date_trunc('day', now()) - (r.days_ago || ' days')::INTERVAL
                      + INTERVAL '9 hours 15 minutes'
                      + ((r.days_ago % 5) * INTERVAL '1 hour');

        INSERT INTO stock_orders (account_id, stock_id, order_type, order_kind,
                                  quantity, order_price, order_date, status, reject_reason)
        VALUES (r.account_id, r.stock_id, r.otype, r.okind, r.qty, r.price, v_order_dt,
                CASE WHEN r.final_status = 'COMPLETED' THEN 'PENDING' ELSE r.final_status END,
                r.reject_reason)
        RETURNING order_id INTO v_order_id;

        IF r.final_status = 'COMPLETED' THEN
            v_match_dt := v_order_dt + INTERVAL '23 minutes';
            v_total := r.qty * r.price;
            v_fee   := ROUND(v_total * 0.0015, 2);                       -- phi 0,15%
            v_tax   := CASE WHEN r.otype = 'SELL'
                            THEN ROUND(v_total * 0.001, 2) ELSE 0 END;   -- thue 0,1%
            v_net   := CASE WHEN r.otype = 'BUY'
                            THEN v_total + v_fee
                            ELSE v_total - v_fee - v_tax END;

            INSERT INTO transactions (order_id, account_id, stock_id, transaction_type,
                                      quantity, price, total_amount, transaction_fee,
                                      tax_amount, net_amount, transaction_date, settlement_date)
            VALUES (v_order_id, r.account_id, r.stock_id, r.otype, r.qty, r.price,
                    v_total, v_fee, v_tax, v_net, v_match_dt, (v_match_dt + INTERVAL '2 days')::DATE);
        END IF;
    END LOOP;
END $$;

-- Co phieu da qua ngay thanh toan T+2 -> cho phep ban
CALL sp_settle_pending_shares();

-- Dinh gia lai toan bo danh muc theo gia thi truong hien tai
UPDATE portfolios p
   SET current_value = p.quantity * s.current_price,
       profit_loss   = p.quantity * (s.current_price - p.average_price),
       updated_at    = now()
  FROM stocks s
 WHERE s.stock_id = p.stock_id;

-- ---------------------------------------------------------------------
-- Phong toa tien cho cac lenh MUA dang cho khop
-- (lenh MP duoc phong toa theo gia tran de dam bao du suc mua)
-- ---------------------------------------------------------------------
UPDATE investment_accounts a
   SET blocked_balance = x.amount,
       cash_balance    = a.cash_balance - x.amount
  FROM (
        SELECT o.account_id,
               ROUND(SUM(o.quantity
                         * COALESCE(NULLIF(o.order_price, 0), s.ceiling_price)
                         * 1.0015), 2) AS amount
          FROM stock_orders o
          JOIN stocks s ON s.stock_id = o.stock_id
         WHERE o.order_type = 'BUY'
           AND o.status IN ('PENDING','PARTIAL')
         GROUP BY o.account_id
       ) x
 WHERE x.account_id = a.account_id;

-- Tong tai san = tien kha dung + tien phong toa + gia tri danh muc
UPDATE investment_accounts a
   SET total_asset_value = a.cash_balance + a.blocked_balance
                         + COALESCE((SELECT SUM(p.current_value)
                                       FROM portfolios p
                                      WHERE p.account_id = a.account_id), 0),
       updated_at = now();
