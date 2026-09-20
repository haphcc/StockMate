-- =====================================================================
-- File 06: LICH SU GIA (stock_price_history)
-- Sinh ~130 phien gan nhat (loai thu 7, chu nhat) cho TAT CA cac ma,
-- theo mo hinh buoc ngau nhien va NEO vao reference_price:
--     close cua phien gan nhat = reference_price (gia dong cua hom truoc)
-- Du lieu nay dung de ve bieu do nen / duong gia trong app Flutter.
-- setseed() giup moi lan chay deu sinh ra cung mot bo du lieu.
-- =====================================================================

SELECT setseed(0.42);

INSERT INTO stock_price_history (stock_id, recorded_date, open_price, close_price,
                                 highest_price, lowest_price, trading_volume, trading_value)
WITH sessions AS (
    SELECT g::DATE AS dt, ROW_NUMBER() OVER (ORDER BY g) AS idx
      FROM generate_series(CURRENT_DATE - INTERVAL '190 days',
                           CURRENT_DATE - INTERVAL '1 day',
                           INTERVAL '1 day') g
     WHERE EXTRACT(ISODOW FROM g) < 6          -- bo thu 7 & chu nhat
),
noise AS (
    SELECT s.stock_id, s.exchange, s.listed_shares, s.reference_price,
           d.dt, d.idx,
           ((random() - 0.48) * 0.035)::NUMERIC AS ret,  -- bien dong ~ +/-1,75% moi phien
           random()::NUMERIC                    AS r_hi,
           random()::NUMERIC                    AS r_lo,
           random()::NUMERIC                    AS r_vol
      FROM stocks s
      CROSS JOIN sessions d
),
walk AS (
    SELECT n.*,
           SUM(ret) OVER (PARTITION BY stock_id ORDER BY idx) AS cum,
           SUM(ret) OVER (PARTITION BY stock_id)              AS tot
      FROM noise n
),
closes AS (
    SELECT w.*,
           GREATEST(reference_price * EXP(cum - tot), 1000::NUMERIC) AS close_raw
      FROM walk w
),
rounded AS (
    SELECT c.*,
           fn_price_tick(c.exchange, c.close_raw) AS tick,
           ROUND(c.close_raw / fn_price_tick(c.exchange, c.close_raw))
               * fn_price_tick(c.exchange, c.close_raw) AS close_px
      FROM closes c
),
ohlc AS (
    SELECT r.stock_id, r.dt, r.tick, r.listed_shares, r.r_hi, r.r_lo, r.r_vol,
           r.close_px,
           COALESCE(LAG(r.close_px) OVER (PARTITION BY r.stock_id ORDER BY r.idx),
                    r.close_px) AS open_px
      FROM rounded r
)
SELECT o.stock_id,
       o.dt,
       o.open_px,
       o.close_px,
       ROUND((GREATEST(o.open_px, o.close_px) * (1 + o.r_hi * 0.012)) / o.tick) * o.tick,
       ROUND((LEAST   (o.open_px, o.close_px) * (1 - o.r_lo * 0.012)) / o.tick) * o.tick,
       FLOOR(GREATEST(o.listed_shares * 0.0006, 30000) * (0.4 + o.r_vol * 1.2) / 100) * 100,
       ROUND(o.close_px * FLOOR(GREATEST(o.listed_shares * 0.0006, 30000)
                                * (0.4 + o.r_vol * 1.2) / 100) * 100, 2)
  FROM ohlc o;

-- Bao dam rang buoc high >= max(open, close) va low <= min(open, close)
UPDATE stock_price_history
   SET highest_price = GREATEST(highest_price, open_price, close_price),
       lowest_price  = LEAST   (lowest_price,  open_price, close_price);

-- Khoi luong khop cua phien hien tai tren bang gia = KL phien gan nhat
UPDATE stocks s
   SET total_volume = h.trading_volume
  FROM (SELECT DISTINCT ON (stock_id) stock_id, trading_volume
          FROM stock_price_history
         ORDER BY stock_id, recorded_date DESC) h
 WHERE h.stock_id = s.stock_id;
