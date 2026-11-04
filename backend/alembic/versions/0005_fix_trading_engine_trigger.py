"""Update fn_apply_transaction to support CASH-01 fund reservation and SHARE-01 share blocking.

Revision ID: 0005_fix_trading_engine_trigger
Revises: 0004_share_settlements
Create Date: 2026-11-04 10:30:00
Owner: TV5 - Tuệ / TV1 - Phuoc
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0005_fix_trading_engine_trigger"
down_revision: Union[str, None] = "0004_share_settlements"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # Update fn_apply_transaction to handle blocked_balance reservation and refunds correctly
    bind.execute(
        sa.text(
            """
            CREATE OR REPLACE FUNCTION fn_apply_transaction()
            RETURNS TRIGGER
            LANGUAGE plpgsql AS $$
            DECLARE
                v_price       NUMERIC(12,2);
                v_avail_delta INTEGER;
                v_order_price NUMERIC(12,2);
                v_order_gross NUMERIC(20,2);
                v_order_fee   NUMERIC(20,2);
                v_reserve     NUMERIC(20,2);
                v_refund      NUMERIC(20,2);
            BEGIN
                IF NEW.transaction_type = 'BUY' THEN
                    -- Co phieu mua ve chi kha dung sau ngay thanh toan T+2
                    v_avail_delta := CASE
                        WHEN COALESCE(NEW.settlement_date, CURRENT_DATE) <= CURRENT_DATE
                        THEN NEW.quantity ELSE 0 END;

                    INSERT INTO portfolios (
                        account_id, stock_id, quantity, available_quantity, blocked_quantity,
                        average_price, updated_at
                    )
                    VALUES (
                        NEW.account_id, NEW.stock_id, NEW.quantity,
                        v_avail_delta, 0, NEW.price, now()
                    )
                    ON CONFLICT (account_id, stock_id) DO UPDATE
                       SET average_price      = ROUND(
                           (portfolios.quantity * portfolios.average_price
                            + EXCLUDED.quantity * EXCLUDED.average_price)
                           / NULLIF(portfolios.quantity + EXCLUDED.quantity, 0), 2),
                           quantity           = portfolios.quantity + EXCLUDED.quantity,
                           available_quantity = portfolios.available_quantity
                                                + EXCLUDED.available_quantity,
                           updated_at         = now();

                    -- Giai toa blocked_balance va hoan lai chenh lech gia khop (CASH-01)
                    SELECT order_price INTO v_order_price
                      FROM stock_orders WHERE order_id = NEW.order_id;
                    IF v_order_price IS NOT NULL THEN
                        v_order_gross := NEW.quantity * v_order_price;
                        v_order_fee   := ROUND(v_order_gross * 0.0015, 2);
                        v_reserve     := v_order_gross + v_order_fee;
                        v_refund      := v_reserve - NEW.net_amount;

                        UPDATE investment_accounts
                           SET blocked_balance = GREATEST(blocked_balance - v_reserve, 0),
                               cash_balance    = cash_balance + v_refund,
                               updated_at      = now()
                         WHERE account_id = NEW.account_id;
                    ELSE
                        UPDATE investment_accounts
                           SET cash_balance = cash_balance - NEW.net_amount,
                               updated_at   = now()
                         WHERE account_id = NEW.account_id;
                    END IF;

                ELSE  -- SELL: giai toa blocked_quantity va cong tien thuc nhan (SHARE-01)
                    UPDATE portfolios
                       SET quantity           = quantity - NEW.quantity,
                           blocked_quantity   = GREATEST(blocked_quantity - NEW.quantity, 0),
                           updated_at         = now()
                     WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id;

                    DELETE FROM portfolios
                     WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id AND quantity = 0;

                    UPDATE investment_accounts
                       SET cash_balance = cash_balance + NEW.net_amount,
                           updated_at   = now()
                     WHERE account_id = NEW.account_id;
                END IF;

                -- Dinh gia lai dong danh muc vua thay doi
                SELECT current_price INTO v_price FROM stocks WHERE stock_id = NEW.stock_id;
                UPDATE portfolios
                   SET current_value = quantity * v_price,
                       profit_loss   = quantity * (v_price - average_price)
                 WHERE account_id = NEW.account_id AND stock_id = NEW.stock_id;

                -- Cap nhat lenh goc
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
            """
        )
    )


def downgrade() -> None:
    pass
