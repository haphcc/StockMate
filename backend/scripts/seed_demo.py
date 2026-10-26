"""Seed demo data for StockMate DEV database.

Owner: TV1 - Phuoc
Requirements:
- Run in a single transaction.
- Protect against concurrent execution (advisory lock).
- Reject if database already has data (prevent overwriting/duplication).
- Generate REAL bcrypt password hashes for demo users (password: 'Matkhau@123').
"""

import os
import sys
from pathlib import Path

import bcrypt
import psycopg
from dotenv import load_dotenv

# Load environment variables
BASE_DIR = Path(__file__).resolve().parents[1]
dotenv_path = BASE_DIR / ".env"
if dotenv_path.exists():
    load_dotenv(dotenv_path)

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://postgres:h%24c4122005@localhost:5432/stock_exchange",
)
# Convert SQLAlchemy dialect format (postgresql+psycopg://) to standard URI if needed
if DATABASE_URL.startswith("postgresql+psycopg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql+psycopg://", "postgresql://", 1)

DEMO_PASSWORD = "Matkhau@123"
ADVISORY_LOCK_ID = 42122005


def get_real_bcrypt_hash(password: str) -> str:
    """Generate real bcrypt hash compatible with passlib/fastapi."""
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def seed() -> int:
    print("Connecting to database to seed demo data...")
    pw_hash = get_real_bcrypt_hash(DEMO_PASSWORD)

    try:
        with psycopg.connect(DATABASE_URL, autocommit=False) as conn:
            with conn.cursor() as cur:
                # 1. Acquire advisory lock to prevent concurrent runs
                cur.execute("SELECT pg_try_advisory_xact_lock(%s);", (ADVISORY_LOCK_ID,))
                got_lock = cur.fetchone()[0]
                if not got_lock:
                    print("ERROR: Another seed process is currently running. Aborted.")
                    return 1

                # 2. Check if database already has customers or stocks
                cur.execute("SELECT COUNT(*) FROM customers;")
                customer_count = cur.fetchone()[0]

                cur.execute("SELECT COUNT(*) FROM stocks;")
                stock_count = cur.fetchone()[0]

                if customer_count > 0:
                    print(
                        f"REJECTED: Database already contains {customer_count} customers. "
                        "Seed aborted to prevent overwriting or duplicate data."
                    )
                    return 0

                print(
                    f"Database is clean (customers={customer_count}, stocks={stock_count}). "
                    "Seeding data..."
                )

                # 3. Seed Stocks (if empty)
                if stock_count == 0:
                    stocks_file = BASE_DIR.parent / "data/postgres/03_seed_stocks.sql"
                    if stocks_file.exists():
                        print("Seeding stocks from prototype...")
                        cur.execute(stocks_file.read_text(encoding="utf-8"))

                # 4. Seed Customers with real bcrypt password hash
                print(f"Seeding customers with real bcrypt hash for password '{DEMO_PASSWORD}'...")
                customers_data = [
                    (
                        "Nguyễn Văn An",
                        "an.nguyen@gmail.com",
                        "0901234567",
                        pw_hash,
                        "1992-03-14",
                        "001092001234",
                        "123 Lê Lợi, Quận 1, TP.HCM",
                        "ADMIN",
                        "ACTIVE",
                    ),
                    (
                        "Trần Thị Bích",
                        "bich.tran@gmail.com",
                        "0912345678",
                        pw_hash,
                        "1995-07-22",
                        "001195002345",
                        "45 Nguyễn Huệ, Quận 1, TP.HCM",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Lê Minh Cường",
                        "cuong.le@gmail.com",
                        "0923456789",
                        pw_hash,
                        "1988-11-05",
                        "001088003456",
                        "78 Trần Hưng Đạo, Hoàn Kiếm, HN",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Phạm Thu Dung",
                        "dung.pham@gmail.com",
                        "0934567890",
                        pw_hash,
                        "1997-01-30",
                        "001197004567",
                        "12 Bà Triệu, Hai Bà Trưng, HN",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Hoàng Đức Duy",
                        "duy.hoang@gmail.com",
                        "0945678901",
                        pw_hash,
                        "1990-09-18",
                        "001090005678",
                        "9 Hùng Vương, Hải Châu, ĐN",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Vũ Thị Hương",
                        "huong.vu@gmail.com",
                        "0956789012",
                        pw_hash,
                        "1993-05-09",
                        "001193006789",
                        "56 Nguyễn Trãi, Thanh Xuân, HN",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Đặng Quốc Khánh",
                        "khanh.dang@gmail.com",
                        "0967890123",
                        pw_hash,
                        "1985-12-25",
                        "001085007890",
                        "234 Cách Mạng Tháng 8, Q3, HCM",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Bùi Thanh Lam",
                        "lam.bui@gmail.com",
                        "0978901234",
                        pw_hash,
                        "1999-04-02",
                        "001199008901",
                        "17 Lý Thường Kiệt, Ninh Kiều, CT",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Ngô Hải Long",
                        "long.ngo@gmail.com",
                        "0989012345",
                        pw_hash,
                        "1991-08-16",
                        "001091009012",
                        "88 Hoàng Văn Thụ, Tân Bình, HCM",
                        "CUSTOMER",
                        "ACTIVE",
                    ),
                    (
                        "Đỗ Thị Mai",
                        "mai.do@gmail.com",
                        "0990123456",
                        pw_hash,
                        "1996-06-11",
                        "001196000123",
                        "3 Trần Phú, Nha Trang, KH",
                        "CUSTOMER",
                        "PENDING",
                    ),
                ]
                cur.executemany(
                    """
                    INSERT INTO customers (
                        full_name, email, phone_number, password_hash, date_of_birth,
                        id_card_number, address, role, status
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """,
                    customers_data,
                )

                # 5. Seed Investment Accounts
                print("Seeding investment accounts...")
                accounts_sql = """
                INSERT INTO investment_accounts (customer_id, account_number, account_type,
                                                 cash_balance, margin_limit, status, created_at)
                SELECT c.customer_id, v.acc_no, v.acc_type, v.cash, v.margin, v.status,
                       now() - (v.age_days || ' days')::INTERVAL
                FROM (VALUES
                    ('an.nguyen@gmail.com', '068C100001', 'CASH', 500000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 720),
                    ('an.nguyen@gmail.com', '068C100002', 'MARGIN', 300000000::NUMERIC,
                     300000000::NUMERIC, 'ACTIVE', 400),
                    ('bich.tran@gmail.com', '068C100003', 'CASH', 250000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 610),
                    ('cuong.le@gmail.com', '068C100004', 'CASH', 800000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 900),
                    ('cuong.le@gmail.com', '068C100005', 'MARGIN', 1000000000::NUMERIC,
                     1000000000::NUMERIC, 'ACTIVE', 540),
                    ('dung.pham@gmail.com', '068C100006', 'CASH', 120000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 300),
                    ('duy.hoang@gmail.com', '068C100007', 'CASH', 350000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 450),
                    ('huong.vu@gmail.com', '068C100008', 'CASH', 200000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 260),
                    ('khanh.dang@gmail.com', '068C100009', 'MARGIN', 1500000000::NUMERIC,
                     1500000000::NUMERIC, 'ACTIVE', 1100),
                    ('lam.bui@gmail.com', '068C100010', 'CASH', 80000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 150),
                    ('long.ngo@gmail.com', '068C100011', 'CASH', 420000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 380),
                    ('long.ngo@gmail.com', '068C100012', 'CASH', 60000000::NUMERIC,
                     0::NUMERIC, 'SUSPENDED', 95),
                    ('mai.do@gmail.com', '068C100013', 'CASH', 30000000::NUMERIC,
                     0::NUMERIC, 'ACTIVE', 20)
                ) AS v(email, acc_no, acc_type, cash, margin, status, age_days)
                JOIN customers c ON c.email = v.email;
                """
                cur.execute(accounts_sql)

                # 6. Seed Watchlists
                print("Seeding watchlists...")
                cur.execute(
                    """
                    INSERT INTO watchlists (customer_id, stock_id, list_name, target_price, note)
                    SELECT c.customer_id, s.stock_id, v.list_name, v.target_price, v.note
                    FROM (VALUES
                        ('an.nguyen@gmail.com','FPT','Cổ phiếu công nghệ',110000::NUMERIC,
                         'Chờ điều chỉnh về vùng 95 để mua thêm'),
                        ('an.nguyen@gmail.com','MWG','Cổ phiếu công nghệ', 70000::NUMERIC,
                         'Theo dõi KQKD quý'),
                        ('an.nguyen@gmail.com','VCB','Danh mục theo dõi', 68000::NUMERIC,NULL),
                        ('an.nguyen@gmail.com','HPG','Danh mục theo dõi', 30000::NUMERIC,
                         'Chu kỳ thép'),
                        ('bich.tran@gmail.com','VNM','Danh mục theo dõi', 65000::NUMERIC,
                         'Cổ tức đều'),
                        ('bich.tran@gmail.com','SAB','Danh mục theo dõi', 52000::NUMERIC,NULL),
                        ('bich.tran@gmail.com','MCH','Danh mục theo dõi',130000::NUMERIC,NULL)
                    ) AS v(email, symbol, list_name, target_price, note)
                    JOIN customers c ON c.email = v.email
                    JOIN stocks s    ON s.stock_symbol = v.symbol;
                    """
                )

                # 7. Seed Orders and Transactions
                print("Seeding stock orders and executed transactions...")
                trading_file = BASE_DIR.parent / "data/postgres/05_seed_trading.sql"
                if trading_file.exists():
                    cur.execute(trading_file.read_text(encoding="utf-8"))

                # 8. Seed Stock Price History
                print("Seeding stock price history...")
                price_hist_file = BASE_DIR.parent / "data/postgres/06_seed_price_history.sql"
                if price_hist_file.exists():
                    cur.execute(price_hist_file.read_text(encoding="utf-8"))

                # 9. Seed Notifications
                print("Seeding notifications...")
                notif_file = BASE_DIR.parent / "data/postgres/07_seed_notifications.sql"
                if notif_file.exists():
                    cur.execute(notif_file.read_text(encoding="utf-8"))

                # Commit transaction
                conn.commit()
                print("SUCCESS: Demo data seeded successfully with real bcrypt password hashes!")
                return 0

    except Exception as e:
        print(f"ERROR during seed execution: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(seed())
