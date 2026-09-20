-- =====================================================================
-- File 04: KHACH HANG - TAI KHOAN DAU TU - DANH MUC QUAN TAM
-- Mat khau demo cua tat ca tai khoan: Matkhau@123
-- password_hash duoi day la hash MAU (dung dinh dang bcrypt). Truoc khi
-- dang nhap that, hay sinh lai bang passlib:
--     from passlib.context import CryptContext
--     CryptContext(schemes=["bcrypt"]).hash("Matkhau@123")
-- =====================================================================

INSERT INTO customers (full_name, email, phone_number, password_hash, date_of_birth,
                       id_card_number, address, status) VALUES
('Nguyễn Văn An',    'an.nguyen@gmail.com',    '0901234567','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1992-03-14','001092001234','123 Lê Lợi, Quận 1, TP.HCM','ACTIVE'),
('Trần Thị Bích',    'bich.tran@gmail.com',    '0912345678','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1995-07-22','001195002345','45 Nguyễn Huệ, Quận 1, TP.HCM','ACTIVE'),
('Lê Minh Cường',    'cuong.le@gmail.com',     '0923456789','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1988-11-05','001088003456','78 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội','ACTIVE'),
('Phạm Thu Dung',    'dung.pham@gmail.com',    '0934567890','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1997-01-30','001197004567','12 Bà Triệu, Hai Bà Trưng, Hà Nội','ACTIVE'),
('Hoàng Đức Duy',    'duy.hoang@gmail.com',    '0945678901','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1990-09-18','001090005678','9 Hùng Vương, Hải Châu, Đà Nẵng','ACTIVE'),
('Vũ Thị Hương',     'huong.vu@gmail.com',     '0956789012','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1993-05-09','001193006789','56 Nguyễn Trãi, Thanh Xuân, Hà Nội','ACTIVE'),
('Đặng Quốc Khánh',  'khanh.dang@gmail.com',   '0967890123','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1985-12-25','001085007890','234 Cách Mạng Tháng 8, Quận 3, TP.HCM','ACTIVE'),
('Bùi Thanh Lam',    'lam.bui@gmail.com',      '0978901234','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1999-04-02','001199008901','17 Lý Thường Kiệt, Ninh Kiều, Cần Thơ','ACTIVE'),
('Ngô Hải Long',     'long.ngo@gmail.com',     '0989012345','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1991-08-16','001091009012','88 Hoàng Văn Thụ, Quận Tân Bình, TP.HCM','ACTIVE'),
('Đỗ Thị Mai',       'mai.do@gmail.com',       '0990123456','$2b$12$seedhashseedhashseedhaOxQ1YV9kR0m6cJ1bQeF3oWQ9sDQfN2','1996-06-11','001196000123','3 Trần Phú, Nha Trang, Khánh Hòa','PENDING');

-- ---------------------------------------------------------------------
-- Tai khoan dau tu.  cash_balance o day la SO TIEN NAP BAN DAU;
-- sau khi chay file 05, trigger se tru/cong theo cac giao dich da khop.
-- Quy uoc so TK: 068C + 6 chu so (giong ma so luu ky cua CTCK)
-- ---------------------------------------------------------------------
INSERT INTO investment_accounts (customer_id, account_number, account_type,
                                 cash_balance, margin_limit, status, created_at)
SELECT c.customer_id, v.acc_no, v.acc_type, v.cash, v.margin, v.status, now() - (v.age_days || ' days')::INTERVAL
FROM (VALUES
    ('an.nguyen@gmail.com',  '068C100001','CASH',   500000000::NUMERIC,          0::NUMERIC,'ACTIVE',720),
    ('an.nguyen@gmail.com',  '068C100002','MARGIN', 300000000::NUMERIC, 300000000::NUMERIC,'ACTIVE',400),
    ('bich.tran@gmail.com',  '068C100003','CASH',   250000000::NUMERIC,          0::NUMERIC,'ACTIVE',610),
    ('cuong.le@gmail.com',   '068C100004','CASH',   800000000::NUMERIC,          0::NUMERIC,'ACTIVE',900),
    ('cuong.le@gmail.com',   '068C100005','MARGIN',1000000000::NUMERIC,1000000000::NUMERIC,'ACTIVE',540),
    ('dung.pham@gmail.com',  '068C100006','CASH',   120000000::NUMERIC,          0::NUMERIC,'ACTIVE',300),
    ('duy.hoang@gmail.com',  '068C100007','CASH',   350000000::NUMERIC,          0::NUMERIC,'ACTIVE',450),
    ('huong.vu@gmail.com',   '068C100008','CASH',   200000000::NUMERIC,          0::NUMERIC,'ACTIVE',260),
    ('khanh.dang@gmail.com', '068C100009','MARGIN',1500000000::NUMERIC,1500000000::NUMERIC,'ACTIVE',1100),
    ('lam.bui@gmail.com',    '068C100010','CASH',    80000000::NUMERIC,          0::NUMERIC,'ACTIVE',150),
    ('long.ngo@gmail.com',   '068C100011','CASH',   420000000::NUMERIC,          0::NUMERIC,'ACTIVE',380),
    ('long.ngo@gmail.com',   '068C100012','CASH',    60000000::NUMERIC,          0::NUMERIC,'SUSPENDED',95),
    ('mai.do@gmail.com',     '068C100013','CASH',    30000000::NUMERIC,          0::NUMERIC,'ACTIVE',20)
) AS v(email, acc_no, acc_type, cash, margin, status, age_days)
JOIN customers c ON c.email = v.email;

-- ---------------------------------------------------------------------
-- Danh muc quan tam (Watchlist)
-- ---------------------------------------------------------------------
INSERT INTO watchlists (customer_id, stock_id, list_name, target_price, note)
SELECT c.customer_id, s.stock_id, v.list_name, v.target_price, v.note
FROM (VALUES
    ('an.nguyen@gmail.com','FPT','Cổ phiếu công nghệ',110000::NUMERIC,'Chờ điều chỉnh về vùng 95 để mua thêm'),
    ('an.nguyen@gmail.com','MWG','Cổ phiếu công nghệ', 70000::NUMERIC,'Theo dõi KQKD quý'),
    ('an.nguyen@gmail.com','VCB','Danh mục theo dõi', 68000::NUMERIC,NULL),
    ('an.nguyen@gmail.com','HPG','Danh mục theo dõi', 30000::NUMERIC,'Chu kỳ thép'),
    ('bich.tran@gmail.com','VNM','Danh mục theo dõi', 65000::NUMERIC,'Cổ tức đều'),
    ('bich.tran@gmail.com','SAB','Danh mục theo dõi', 52000::NUMERIC,NULL),
    ('bich.tran@gmail.com','MCH','Danh mục theo dõi',130000::NUMERIC,NULL),
    ('cuong.le@gmail.com','SSI','Nhóm chứng khoán',  32000::NUMERIC,'Beta cao, đánh sóng'),
    ('cuong.le@gmail.com','VND','Nhóm chứng khoán',  18000::NUMERIC,NULL),
    ('cuong.le@gmail.com','SHS','Nhóm chứng khoán',  17000::NUMERIC,NULL),
    ('cuong.le@gmail.com','MBS','Nhóm chứng khoán',  32000::NUMERIC,NULL),
    ('dung.pham@gmail.com','TCB','Danh mục theo dõi',28000::NUMERIC,NULL),
    ('dung.pham@gmail.com','MBB','Danh mục theo dõi',27000::NUMERIC,'Tích lũy dài hạn'),
    ('duy.hoang@gmail.com','GAS','Nhóm dầu khí',     75000::NUMERIC,NULL),
    ('duy.hoang@gmail.com','BSR','Nhóm dầu khí',     25000::NUMERIC,NULL),
    ('duy.hoang@gmail.com','PVS','Nhóm dầu khí',     38000::NUMERIC,'Hưởng lợi dự án Lô B'),
    ('huong.vu@gmail.com','VIC','Danh mục theo dõi',105000::NUMERIC,NULL),
    ('huong.vu@gmail.com','VHM','Danh mục theo dõi', 85000::NUMERIC,NULL),
    ('khanh.dang@gmail.com','DGC','Danh mục theo dõi',115000::NUMERIC,NULL),
    ('khanh.dang@gmail.com','ACV','Danh mục theo dõi',105000::NUMERIC,'Hàng không phục hồi'),
    ('khanh.dang@gmail.com','VGI','Danh mục theo dõi', 95000::NUMERIC,NULL),
    ('lam.bui@gmail.com','SHB','Danh mục theo dõi',   14000::NUMERIC,'Giá thấp, hợp vốn nhỏ'),
    ('lam.bui@gmail.com','VIX','Danh mục theo dõi',   15000::NUMERIC,NULL),
    ('long.ngo@gmail.com','HPG','Danh mục theo dõi',  32000::NUMERIC,NULL),
    ('long.ngo@gmail.com','KBC','Danh mục theo dõi',  32000::NUMERIC,'KCN hưởng lợi FDI'),
    ('long.ngo@gmail.com','IDC','Danh mục theo dõi',  48000::NUMERIC,NULL),
    ('mai.do@gmail.com','VNM','Danh mục theo dõi',    64000::NUMERIC,NULL)
) AS v(email, symbol, list_name, target_price, note)
JOIN customers c ON c.email = v.email
JOIN stocks    s ON s.stock_symbol = v.symbol;
