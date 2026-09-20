-- =====================================================================
-- File 07: THONG BAO (notifications)
-- Sinh tu du lieu that da co: khop lenh, lenh cho, canh bao gia theo
-- watchlist, thong bao he thong.
-- =====================================================================

-- 1) Thong bao khop lenh (lay 40 giao dich gan nhat)
INSERT INTO notifications (customer_id, title, content, notification_type, ref_id, is_read, created_at)
SELECT a.customer_id,
       CASE t.transaction_type WHEN 'BUY' THEN 'Khớp lệnh mua ' || s.stock_symbol
                                          ELSE 'Khớp lệnh bán ' || s.stock_symbol END,
       'Lệnh ' || CASE t.transaction_type WHEN 'BUY' THEN 'mua' ELSE 'bán' END || ' '
       || TO_CHAR(t.quantity, 'FM999G999') || ' ' || s.stock_symbol
       || ' giá ' || TO_CHAR(t.price, 'FM999G999') || 'đ đã khớp thành công. Giá trị '
       || TO_CHAR(t.total_amount, 'FM999G999G999') || 'đ, phí '
       || TO_CHAR(t.transaction_fee, 'FM999G999G999') || 'đ.',
       'TRANSACTION',
       t.transaction_id,
       (t.transaction_date < now() - INTERVAL '7 days'),
       t.transaction_date
  FROM transactions t
  JOIN investment_accounts a ON a.account_id = t.account_id
  JOIN stocks s              ON s.stock_id   = t.stock_id
 ORDER BY t.transaction_date DESC
 LIMIT 40;

-- 2) Thong bao ve cac lenh dang cho khop / bi huy / bi tu choi
INSERT INTO notifications (customer_id, title, content, notification_type, ref_id, is_read, created_at)
SELECT a.customer_id,
       CASE o.status
            WHEN 'PENDING'   THEN 'Lệnh ' || s.stock_symbol || ' đang chờ khớp'
            WHEN 'CANCELLED' THEN 'Lệnh ' || s.stock_symbol || ' đã được huỷ'
            ELSE                  'Lệnh ' || s.stock_symbol || ' bị từ chối'
       END,
       'Lệnh ' || CASE o.order_type WHEN 'BUY' THEN 'mua' ELSE 'bán' END || ' '
       || TO_CHAR(o.quantity, 'FM999G999') || ' ' || s.stock_symbol
       || CASE WHEN o.order_price > 0
               THEN ' giá ' || TO_CHAR(o.order_price, 'FM999G999') || 'đ'
               ELSE ' lệnh thị trường (MP)' END
       || CASE o.status
               WHEN 'PENDING'   THEN ' đã được gửi vào sàn và đang chờ khớp.'
               WHEN 'CANCELLED' THEN ' đã được huỷ theo yêu cầu của quý khách.'
               ELSE ' bị từ chối. Lý do: ' || COALESCE(o.reject_reason, 'không xác định') || '.'
          END,
       'ORDER', o.order_id, FALSE, o.order_date
  FROM stock_orders o
  JOIN investment_accounts a ON a.account_id = o.account_id
  JOIN stocks s              ON s.stock_id   = o.stock_id
 WHERE o.status IN ('PENDING','CANCELLED','REJECTED');

-- 3) Canh bao gia: ma trong watchlist da cham/vuot gia ky vong
INSERT INTO notifications (customer_id, title, content, notification_type, ref_id, is_read, created_at)
SELECT w.customer_id,
       'Cảnh báo giá ' || s.stock_symbol,
       s.stock_symbol || ' hiện ở mức ' || TO_CHAR(s.current_price, 'FM999G999')
       || 'đ, ' || CASE WHEN s.current_price >= w.target_price THEN 'đã vượt' ELSE 'đã về dưới' END
       || ' mức giá quan tâm ' || TO_CHAR(w.target_price, 'FM999G999') || 'đ của quý khách.',
       'PRICE_ALERT', s.stock_id, FALSE, now() - INTERVAL '4 hours'
  FROM watchlists w
  JOIN stocks s ON s.stock_id = w.stock_id
 WHERE w.target_price IS NOT NULL
   AND (s.current_price >= w.target_price OR s.current_price <= w.target_price * 0.9);

-- 4) Thong bao nap/rut tien (mo phong tu so du ban dau)
INSERT INTO notifications (customer_id, title, content, notification_type, ref_id, is_read, created_at)
SELECT a.customer_id,
       'Nạp tiền thành công',
       'Tài khoản ' || a.account_number || ' vừa được nạp thành công. Số dư khả dụng hiện tại: '
       || TO_CHAR(a.cash_balance, 'FM999G999G999G999') || 'đ.',
       'CASH', a.account_id, TRUE, a.created_at + INTERVAL '1 hour'
  FROM investment_accounts a
 WHERE a.status = 'ACTIVE';

-- 5) Thong bao he thong / tin tuc thi truong (gui cho moi khach hang)
INSERT INTO notifications (customer_id, title, content, notification_type, ref_id, is_read, created_at)
SELECT c.customer_id, v.title, v.content, v.ntype, NULL, v.is_read,
       now() - (v.hours_ago || ' hours')::INTERVAL
  FROM customers c
  CROSS JOIN (VALUES
    ('Lịch nghỉ giao dịch',
     'HOSE và HNX sẽ tạm ngừng giao dịch trong các ngày lễ theo thông báo của Sở. Quý khách vui lòng sắp xếp kế hoạch đầu tư phù hợp.',
     'SYSTEM', TRUE, 72),
    ('Bảo trì hệ thống định kỳ',
     'Hệ thống sẽ bảo trì từ 22:00 đến 23:30 thứ Bảy hàng tuần. Trong thời gian này, tính năng đặt lệnh trước phiên sẽ tạm ngưng.',
     'SYSTEM', FALSE, 26),
    ('Thị trường phiên hôm nay',
     'VN-Index đóng cửa tăng nhẹ với thanh khoản cải thiện, dòng tiền tập trung vào nhóm ngân hàng và chứng khoán.',
     'NEWS', FALSE, 5)
  ) AS v(title, content, ntype, is_read, hours_ago)
 WHERE c.status = 'ACTIVE';
