-- =====================================================================
-- StockMate Baseline Schema (0001_schema.sql)
-- Owner: TV1 - Phuoc
-- PostgreSQL 16+ DDL
-- Quy uoc: tien VND numeric(20,2) | gia co phieu numeric(12,2) - don vi dong
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CUSTOMERS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id     BIGINT GENERATED ALWAYS AS IDENTITY,
    full_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(150)  NOT NULL,
    phone_number    VARCHAR(15)   NOT NULL,
    password_hash   VARCHAR(255)  NOT NULL,
    date_of_birth   DATE,
    id_card_number  VARCHAR(20),
    address         VARCHAR(255),
    avatar_url      VARCHAR(255),
    status          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email  UNIQUE (email),
    CONSTRAINT uq_customers_phone  UNIQUE (phone_number),
    CONSTRAINT uq_customers_idcard UNIQUE (id_card_number),
    CONSTRAINT ck_customers_status CHECK (status IN ('PENDING','ACTIVE','LOCKED','CLOSED'))
);

-- ---------------------------------------------------------------------
-- 2. INVESTMENT ACCOUNTS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS investment_accounts (
    account_id        BIGINT        GENERATED ALWAYS AS IDENTITY,
    customer_id       BIGINT        NOT NULL,
    account_number    VARCHAR(20)   NOT NULL,
    account_type      VARCHAR(20)   NOT NULL DEFAULT 'CASH',
    cash_balance      NUMERIC(20,2) NOT NULL DEFAULT 0,
    blocked_balance   NUMERIC(20,2) NOT NULL DEFAULT 0,
    total_asset_value NUMERIC(20,2) NOT NULL DEFAULT 0,
    margin_limit      NUMERIC(20,2) NOT NULL DEFAULT 0,
    status            VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_investment_accounts PRIMARY KEY (account_id),
    CONSTRAINT uq_accounts_number UNIQUE (account_number),
    CONSTRAINT fk_accounts_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE,
    CONSTRAINT ck_accounts_type   CHECK (account_type IN ('CASH','MARGIN')),
    CONSTRAINT ck_accounts_status CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
    CONSTRAINT ck_accounts_cash   CHECK (cash_balance >= 0 AND blocked_balance >= 0)
);

CREATE INDEX IF NOT EXISTS idx_accounts_customer ON investment_accounts (customer_id);

-- ---------------------------------------------------------------------
-- 3. STOCKS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stocks (
    stock_id        BIGINT        GENERATED ALWAYS AS IDENTITY,
    stock_symbol    VARCHAR(10)   NOT NULL,
    company_name    VARCHAR(200)  NOT NULL,
    exchange        VARCHAR(10)   NOT NULL,
    industry        VARCHAR(100),
    listed_shares   BIGINT        NOT NULL DEFAULT 0,
    current_price   NUMERIC(12,2) NOT NULL DEFAULT 0,
    reference_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    ceiling_price   NUMERIC(12,2) NOT NULL DEFAULT 0,
    floor_price     NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_volume    BIGINT        NOT NULL DEFAULT 0,
    status          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_stocks PRIMARY KEY (stock_id),
    CONSTRAINT uq_stocks_symbol   UNIQUE (stock_symbol),
    CONSTRAINT ck_stocks_exchange CHECK (exchange IN ('HOSE','HNX','UPCOM')),
    CONSTRAINT ck_stocks_status   CHECK (status IN ('ACTIVE','HALTED','DELISTED')),
    CONSTRAINT ck_stocks_price    CHECK (current_price >= 0 AND reference_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_stocks_exchange ON stocks (exchange);
CREATE INDEX IF NOT EXISTS idx_stocks_industry ON stocks (industry);

-- ---------------------------------------------------------------------
-- 4. PORTFOLIOS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS portfolios (
    portfolio_id       BIGINT        GENERATED ALWAYS AS IDENTITY,
    account_id         BIGINT        NOT NULL,
    stock_id           BIGINT        NOT NULL,
    quantity           INTEGER       NOT NULL DEFAULT 0,
    available_quantity INTEGER       NOT NULL DEFAULT 0,
    blocked_quantity   INTEGER       NOT NULL DEFAULT 0,
    average_price      NUMERIC(12,2) NOT NULL DEFAULT 0,
    current_value      NUMERIC(20,2) NOT NULL DEFAULT 0,
    profit_loss        NUMERIC(20,2) NOT NULL DEFAULT 0,
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_portfolios PRIMARY KEY (portfolio_id),
    CONSTRAINT uq_portfolio_account_stock UNIQUE (account_id, stock_id),
    CONSTRAINT fk_portfolio_account FOREIGN KEY (account_id)
        REFERENCES investment_accounts (account_id) ON DELETE CASCADE,
    CONSTRAINT fk_portfolio_stock FOREIGN KEY (stock_id) REFERENCES stocks (stock_id),
    CONSTRAINT ck_portfolio_qty CHECK (
        quantity >= 0 AND
        available_quantity >= 0 AND
        blocked_quantity >= 0 AND
        available_quantity + blocked_quantity <= quantity
    )
);

CREATE INDEX IF NOT EXISTS idx_portfolio_account ON portfolios (account_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_stock   ON portfolios (stock_id);

-- ---------------------------------------------------------------------
-- 5. STOCK ORDERS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stock_orders (
    order_id        BIGINT        GENERATED ALWAYS AS IDENTITY,
    account_id      BIGINT        NOT NULL,
    stock_id        BIGINT        NOT NULL,
    client_order_id UUID          NOT NULL DEFAULT gen_random_uuid(),
    order_type      VARCHAR(10)   NOT NULL,
    order_kind      VARCHAR(10)   NOT NULL DEFAULT 'LO',
    quantity        INTEGER       NOT NULL,
    filled_quantity INTEGER       NOT NULL DEFAULT 0,
    order_price     NUMERIC(12,2) NOT NULL DEFAULT 0,
    order_date      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    matched_at      TIMESTAMPTZ,
    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    reject_reason   VARCHAR(255),
    CONSTRAINT pk_stock_orders PRIMARY KEY (order_id),
    CONSTRAINT uq_orders_account_client_id UNIQUE (account_id, client_order_id),
    CONSTRAINT fk_order_account FOREIGN KEY (account_id)
        REFERENCES investment_accounts (account_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_stock FOREIGN KEY (stock_id) REFERENCES stocks (stock_id),
    CONSTRAINT ck_order_type   CHECK (order_type IN ('BUY','SELL')),
    CONSTRAINT ck_order_kind   CHECK (order_kind IN ('LO','MP','ATO','ATC')),
    CONSTRAINT ck_order_status CHECK (status IN ('PENDING','PARTIAL','COMPLETED','CANCELLED','REJECTED')),
    CONSTRAINT ck_order_qty    CHECK (quantity > 0 AND filled_quantity >= 0 AND filled_quantity <= quantity)
);

CREATE INDEX IF NOT EXISTS idx_orders_account_date ON stock_orders (account_id, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status       ON stock_orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_stock        ON stock_orders (stock_id);

-- ---------------------------------------------------------------------
-- 6. TRANSACTIONS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id   BIGINT        GENERATED ALWAYS AS IDENTITY,
    order_id         BIGINT        NOT NULL,
    account_id       BIGINT        NOT NULL,
    stock_id         BIGINT        NOT NULL,
    transaction_type VARCHAR(10)   NOT NULL,
    quantity         INTEGER       NOT NULL,
    price            NUMERIC(12,2) NOT NULL,
    total_amount     NUMERIC(20,2) NOT NULL,
    transaction_fee  NUMERIC(20,2) NOT NULL DEFAULT 0,
    tax_amount       NUMERIC(20,2) NOT NULL DEFAULT 0,
    net_amount       NUMERIC(20,2) NOT NULL,
    transaction_date TIMESTAMPTZ   NOT NULL DEFAULT now(),
    settlement_date  DATE,
    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT fk_txn_order   FOREIGN KEY (order_id)   REFERENCES stock_orders (order_id),
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id)
        REFERENCES investment_accounts (account_id) ON DELETE CASCADE,
    CONSTRAINT fk_txn_stock   FOREIGN KEY (stock_id)   REFERENCES stocks (stock_id),
    CONSTRAINT ck_txn_type CHECK (transaction_type IN ('BUY','SELL')),
    CONSTRAINT ck_txn_qty  CHECK (quantity > 0 AND price > 0)
);

CREATE INDEX IF NOT EXISTS idx_txn_account_date ON transactions (account_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_txn_stock        ON transactions (stock_id);

-- ---------------------------------------------------------------------
-- 7. WATCHLISTS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS watchlists (
    watchlist_id BIGINT        GENERATED ALWAYS AS IDENTITY,
    customer_id  BIGINT        NOT NULL,
    stock_id     BIGINT        NOT NULL,
    list_name    VARCHAR(50)   NOT NULL DEFAULT 'Danh muc theo doi',
    target_price NUMERIC(12,2),
    note         VARCHAR(255),
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_watchlists PRIMARY KEY (watchlist_id),
    CONSTRAINT uq_watchlist UNIQUE (customer_id, stock_id, list_name),
    CONSTRAINT fk_watchlist_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_watchlist_stock FOREIGN KEY (stock_id)
        REFERENCES stocks (stock_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_watchlist_customer ON watchlists (customer_id);

-- ---------------------------------------------------------------------
-- 8. STOCK PRICE HISTORY
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stock_price_history (
    price_history_id BIGINT        GENERATED ALWAYS AS IDENTITY,
    stock_id         BIGINT        NOT NULL,
    recorded_date    DATE          NOT NULL,
    open_price       NUMERIC(12,2) NOT NULL,
    close_price      NUMERIC(12,2) NOT NULL,
    highest_price    NUMERIC(12,2) NOT NULL,
    lowest_price     NUMERIC(12,2) NOT NULL,
    trading_volume   BIGINT        NOT NULL DEFAULT 0,
    trading_value    NUMERIC(20,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_price_history PRIMARY KEY (price_history_id),
    CONSTRAINT uq_price_history UNIQUE (stock_id, recorded_date),
    CONSTRAINT fk_price_history_stock FOREIGN KEY (stock_id)
        REFERENCES stocks (stock_id) ON DELETE CASCADE,
    CONSTRAINT ck_price_history CHECK (highest_price >= lowest_price)
);

CREATE INDEX IF NOT EXISTS idx_price_history_stock_date ON stock_price_history (stock_id, recorded_date DESC);

-- ---------------------------------------------------------------------
-- 9. NOTIFICATIONS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    notification_id   BIGINT       GENERATED ALWAYS AS IDENTITY,
    customer_id       BIGINT       NOT NULL,
    title             VARCHAR(200) NOT NULL,
    content           TEXT         NOT NULL,
    notification_type VARCHAR(30)  NOT NULL DEFAULT 'SYSTEM',
    ref_id            BIGINT,
    is_read           BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_notifications PRIMARY KEY (notification_id),
    CONSTRAINT fk_notification_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE,
    CONSTRAINT ck_notification_type CHECK (notification_type IN
        ('ORDER','TRANSACTION','PRICE_ALERT','CASH','SYSTEM','NEWS'))
);

CREATE INDEX IF NOT EXISTS idx_notification_customer ON notifications (customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_unread   ON notifications (customer_id) WHERE is_read = FALSE;
