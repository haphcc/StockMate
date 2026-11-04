"""Owner: TV1 - Phuoc.

Payment service integrating payOS VietQR gateway for automated deposits.
"""

import hashlib
import hmac
import logging
import time
from decimal import Decimal
from typing import Any

import httpx
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import ValidationException
from app.models.investment_account import InvestmentAccount
from app.models.notification import Notification

logger = logging.getLogger(__name__)

PAYOS_API_URL = "https://api-merchant.payos.vn/v2/payment-requests"


def create_payos_payment_link(
    account: InvestmentAccount,
    amount: Decimal,
    return_url: str | None = None,
    cancel_url: str | None = None,
) -> dict[str, Any]:
    """Create a real-time VietQR payment link via payOS merchant API."""
    amount_int = int(amount)
    if amount_int <= 0:
        raise ValidationException("Số tiền nạp phải lớn hơn 0 VND.")

    # Generate unique 53-bit integer order code: account_id (prefix) + 10-digit timestamp millis
    timestamp_part = int(time.time() * 1000) % 10000000000
    order_code = int(f"{account.account_id}{timestamp_part:010d}")

    description = f"NAP {account.account_id}"[:25]
    final_return_url = return_url or "https://stockmate.vn/deposit/success"
    final_cancel_url = cancel_url or "https://stockmate.vn/deposit/cancel"

    # Signature string sorted alphabetically by keys:
    # amount, cancelUrl, description, orderCode, returnUrl
    data_str = (
        f"amount={amount_int}"
        f"&cancelUrl={final_cancel_url}"
        f"&description={description}"
        f"&orderCode={order_code}"
        f"&returnUrl={final_return_url}"
    )

    signature = hmac.new(
        settings.PAYOS_CHECKSUM_KEY.encode("utf-8"),
        data_str.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    payload = {
        "orderCode": order_code,
        "amount": amount_int,
        "description": description,
        "returnUrl": final_return_url,
        "cancelUrl": final_cancel_url,
        "signature": signature,
    }

    headers = {
        "x-client-id": settings.PAYOS_CLIENT_ID,
        "x-api-key": settings.PAYOS_API_KEY,
        "Content-Type": "application/json",
    }

    try:
        with httpx.Client(timeout=10.0) as client:
            resp = client.post(PAYOS_API_URL, json=payload, headers=headers)
            body = resp.json()
            if resp.status_code != 200 or body.get("code") != "00":
                desc = body.get("desc") or resp.text
                logger.error("PayOS create link failed: %s", desc)
                raise ValidationException(f"Lỗi cổng thanh toán payOS: {desc}")

            data = body.get("data", {})
            return {
                "order_code": order_code,
                "checkout_url": data.get("checkoutUrl", ""),
                "qr_code": data.get("qrCode", ""),
                "status": data.get("status", "PENDING"),
                "account_id": account.account_id,
                "amount": amount,
            }
    except ValidationException:
        raise
    except Exception as exc:
        logger.exception("Error connecting to payOS: %s", exc)
        raise ValidationException(f"Không thể kết nối đến cổng thanh toán payOS: {exc}") from exc


def verify_payos_webhook_signature(data: dict[str, Any], signature: str) -> bool:
    """Verify payOS webhook HMAC-SHA256 signature against checksum key."""
    if not signature or not isinstance(data, dict):
        return False

    sorted_keys = sorted(data.keys())
    parts = []
    for k in sorted_keys:
        v = data[k]
        if v is not None:
            parts.append(f"{k}={v}")

    data_str = "&".join(parts)
    expected = hmac.new(
        settings.PAYOS_CHECKSUM_KEY.encode("utf-8"),
        data_str.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    return hmac.compare_digest(expected, signature)


def process_payos_webhook(db: Session, webhook_payload: dict[str, Any]) -> tuple[bool, str]:
    """Process payOS webhook notification: verify signature, credit account, create notification."""
    data = webhook_payload.get("data")
    signature = webhook_payload.get("signature", "")

    if not data or not isinstance(data, dict):
        raise ValidationException("Dữ liệu webhook không hợp lệ.")

    if not verify_payos_webhook_signature(data, signature):
        logger.warning("Invalid payOS webhook signature received.")
        raise ValidationException("Chữ ký webhook payOS không hợp lệ.")

    order_code = data.get("orderCode")
    amount = data.get("amount")
    description = str(data.get("description", ""))

    if order_code is None or amount is None:
        raise ValidationException("Thiếu orderCode hoặc amount trong dữ liệu webhook.")

    # Idempotency check: see if notification with ref_id=order_code already exists
    existing = (
        db.query(Notification)
        .filter(
            Notification.ref_id == order_code,
            Notification.notification_type == "CASH",
        )
        .first()
    )
    if existing:
        return True, "Giao dịch đã được xử lý trước đó (Idempotent)."

    # Extract account_id: first try parsing from order_code (prefix before last 10 digits)
    account_id = None
    order_code_str = str(order_code)
    if len(order_code_str) > 10:
        try:
            account_id = int(order_code_str[:-10])
        except ValueError:
            account_id = None

    # Fallback: parse from description 'NAP <account_id>'
    if not account_id and description.startswith("NAP "):
        try:
            account_id = int(description.split()[1])
        except (IndexError, ValueError):
            account_id = None

    if not account_id:
        # If test webhook without account_id, return success without crashing
        logger.info("PayOS test webhook acknowledged (orderCode: %s)", order_code)
        return True, "Xác nhận webhook payOS thành công (test/không xác định tài khoản)."

    account = db.get(InvestmentAccount, account_id)
    if not account:
        logger.error("Investment account %s not found for payOS order %s", account_id, order_code)
        raise ValidationException(f"Không tìm thấy tài khoản đầu tư #{account_id}.")

    # Credit account balance
    deposit_amount = Decimal(str(amount))
    account.cash_balance += deposit_amount

    # Create transaction notification for customer
    formatted_amount = f"{int(deposit_amount):,}"
    noti = Notification(
        customer_id=account.customer_id,
        title="Nạp tiền thành công",
        content=(
            f"Tài khoản {account.account_number} đã được nạp thành công "
            f"+{formatted_amount} VND qua VietQR payOS (Mã GD: {order_code})."
        ),
        notification_type="CASH",
        ref_id=order_code,
        is_read=False,
    )
    db.add(noti)
    db.commit()
    db.refresh(account)

    logger.info(
        "Successfully credited +%s VND to account %s (Order: %s)",
        deposit_amount,
        account.account_number,
        order_code,
    )
    return True, f"Nạp thành công {formatted_amount} VND vào tài khoản {account.account_number}."
