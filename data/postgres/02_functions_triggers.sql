-- =====================================================================
-- File 02: FUNCTION + TRIGGER  (PostgreSQL)
-- Tu dong hoa cac quy tac cua thi truong chung khoan Viet Nam:
--   * Buoc gia + bien do dao dong -> gia tran / gia san
--   * Khop lenh (transactions) -> cap nhat danh muc + so du tien
--   * Gia thi truong thay doi   -> cap nhat gia tri / lai lo danh muc
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1 Buoc gia (tick size)
--   HOSE : < 10.000d -> 10d | 10.000-49.950d -> 50d | >= 50.000d -> 100d
--   HNX / UPCOM : 100d
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_price_tick(p_exchange VARCHAR, p_price NUMERIC)
RETURNS NUMERIC
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
             WHEN p_exchange <> 'HOSE' THEN 100
             WHEN p_price <  10000     THEN 10
             WHEN p_price <  50000     THEN 50
             ELSE 100
           END::NUMERIC;
$$;

-- ---------------------------------------------------------------------
-- 2.2 Bien do dao dong gia trong phien
--   HOSE 7% | HNX 10% | UPCOM 15%
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_price_band(p_exchange VARCHAR)
RETURNS NUMERIC
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_exchange
             WHEN 'HOSE'  THEN 0.07
             WHEN 'HNX'   THEN 0.10
             ELSE 0.15
           END::NUMERIC;
$$;

-- ---------------------------------------------------------------------
-- 2.3 Tinh gia tran / gia san tu gia tham chieu
--     (lam tron ve buoc gia: tran lam tron xuong, san lam tron len)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_price_limits()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_tick NUMERIC;
    v_band NUMERIC;
BEGIN
    v_tick := fn_price_tick(NEW.exchange, NEW.reference_price);
    v_band := fn_price_band(NEW.exchange);

    NEW.ceiling_price := FLOOR(NEW.reference_price * (1 + v_band) / v_tick) * v_tick;
    NEW.floor_price   := CEIL (NEW.reference_price * (1 - v_band) / v_tick) * v_tick;
    IF NEW.floor_price < v_tick THEN
        NEW.floor_price := v_tick;
    END IF;

    IF NEW.current_price = 0 THEN
        NEW.current_price := NEW.reference_price;
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_stocks_price_limits
    BEFORE INSERT OR UPDATE OF reference_price, exchange, current_price ON stocks
    FOR EACH ROW EXECUTE FUNCTION fn_set_price_limits();

-- ---------------------------------------------------------------------
-- 2.4 Cap nhat tong tai san cua mot tai khoan
--     total_asset_value = tien mat + tien phong toa + gia tri danh muc
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_recalc_account_asset(p_account_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE investment_accounts a
       SET total_asset_value = a.cash_balance + a.blocked_balance
                             + COALESCE((SELECT SUM(p.current_value)
                                           FROM portfolios p
                                          WHERE p.account_id = a.account_id), 0),
           updated_at = now()
     WHERE a.account_id = p_account_id;
END;
$$;

-- ---------------------------------------------------------------------
-- 2.5 Khop lenh: INSERT vao transactions se tu dong
--       - cap nhat portfolios (so luong + gia von binh quan)
--       - cap nhat so du tien cua tai khoan
--       - cap nhat filled_quantity / status cua lenh goc
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_apply_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_price       NUMERIC(12,2);
    v_avail_delta INTEGER;
BEGIN
    IF NEW.transaction_type = 'BUY' THEN
        -- co phieu mua ve chi ban duoc sau ngay thanh toan T+2
        v_avail_delta := CASE WHEN COALESCE(NEW.settlement_date, CURRENT_DATE) <= CURRENT_DATE
                              THEN NEW.quantity ELSE 0 END;

        INSERT INTO portfolios (account_id, stock_id, quantity, available_quantity,
                                average_price, updated_at)
        VALUES (NEW.account_id, NEW.stock_id, NEW.quantity, v_avail_delta, NEW.price, now())
        ON CONFLICT (account_id, stock_id) DO UPDATE
           SET average_price      = ROUND((portfolios.quantity * portfolios.average_price
                                           + EXCLUDED.quantity * EXCLUDED.average_price)
                                          / NULLIF(portfolios.quantity + EXCLUDED.quantity, 0), 2),
               quantity           = portfolios.quantity + EXCLUDED.quantity,
               available_quantity = portfolios.available_quantity + EXCLUDED.available_quantity,
               updated_at         = now();

        UPDATE investment_accounts
           SET cash_balance = cash_balance - NEW.net_amount,
               updated_at   = now()
         WHERE account_id = NEW.account_id;
    ELSE  -- SELL: gia von binh quan giu nguyen, chi tru so luong
        UPDATE portfolios
           SET quantity           = quantity - NEW.quantity,
               available_quantity = GREATEST(available_quantity - NEW.quantity, 0),
               updated_at         = now()
         WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id;

        DELETE FROM portfolios
         WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id AND quantity = 0;

        UPDATE investment_accounts
           SET cash_balance = cash_balance + NEW.net_amount,
               updated_at   = now()
         WHERE account_id = NEW.account_id;
    END IF;

    -- dinh gia lai dong danh muc vua thay doi
    SELECT current_price INTO v_price FROM stocks WHERE stock_id = NEW.stock_id;
    UPDATE portfolios
       SET current_value = quantity * v_price,
           profit_loss   = quantity * (v_price - average_price)
     WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id;

    -- cap nhat lenh goc
    UPDATE stock_orders
       SET filled_quantity = LEAST(filled_quantity + NEW.quantity, quantity),
           matched_at      = NEW.transaction_date,
           status          = CASE WHEN filled_quantity + NEW.quantity >= quantity
                                  THEN 'COMPLETED' ELSE 'PARTIAL' END
     WHERE order_id = NEW.order_id;

    PERFORM fn_recalc_account_asset(NEW.account_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_transaction_apply
    AFTER INSERT ON transactions
    FOR EACH ROW EXECUTE FUNCTION fn_apply_transaction();

-- ---------------------------------------------------------------------
-- 2.6 Gia thi truong thay doi -> dinh gia lai toan bo danh muc dang giu
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reprice_portfolios()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE portfolios
       SET current_value = quantity * NEW.current_price,
           profit_loss   = quantity * (NEW.current_price - average_price),
           updated_at    = now()
     WHERE stock_id = NEW.stock_id;

    UPDATE investment_accounts a
       SET total_asset_value = a.cash_balance + a.blocked_balance
                             + COALESCE((SELECT SUM(p.current_value)
                                           FROM portfolios p
                                          WHERE p.account_id = a.account_id), 0)
     WHERE a.account_id IN (SELECT account_id FROM portfolios WHERE stock_id = NEW.stock_id);

    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_stocks_reprice
    AFTER UPDATE OF current_price ON stocks
    FOR EACH ROW WHEN (OLD.current_price IS DISTINCT FROM NEW.current_price)
    EXECUTE FUNCTION fn_reprice_portfolios();

-- ---------------------------------------------------------------------
-- 2.7 Tien ich: giai phong co phieu da ve tai khoan (chay dau moi phien)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_settle_pending_shares()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE portfolios p
       SET available_quantity = p.quantity,
           updated_at         = now()
     WHERE p.available_quantity < p.quantity
       AND NOT EXISTS (
            SELECT 1 FROM transactions t
             WHERE t.account_id = p.account_id
               AND t.stock_id   = p.stock_id
               AND t.transaction_type = 'BUY'
               AND t.settlement_date > CURRENT_DATE);
END;
$$;

-- ---------------------------------------------------------------------
-- 2.8 Tien ich: dat gia khop moi cho mot ma (dung cho job cap nhat gia)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_update_market_price(p_symbol VARCHAR, p_price NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE stocks
       SET current_price = p_price,
           total_volume  = total_volume + 0,
           updated_at    = now()
     WHERE stock_symbol = p_symbol;
END;
$$;
