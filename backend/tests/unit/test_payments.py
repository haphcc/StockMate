"""Unit tests for payOS VietQR deposit and webhook processing."""

import hashlib
import hmac
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest

from app.core.config import settings
from app.core.errors import ValidationException
from app.models.investment_account import InvestmentAccount
from app.models.notification import Notification
from app.services.payment_service import (
    create_payos_payment_link,
    process_payos_webhook,
    verify_payos_webhook_signature,
)


def test_verify_payos_webhook_signature():
    data = {
        "orderCode": 123456,
        "amount": 50000,
        "description": "NAP 1",
        "reference": "REF123",
    }
    sorted_parts = ["amount=50000", "description=NAP 1", "orderCode=123456", "reference=REF123"]
    data_str = "&".join(sorted_parts)
    valid_sig = hmac.new(
        settings.PAYOS_CHECKSUM_KEY.encode("utf-8"),
        data_str.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    assert verify_payos_webhook_signature(data, valid_sig) is True
    assert verify_payos_webhook_signature(data, "invalid_signature") is False
    assert verify_payos_webhook_signature({}, "") is False


def test_create_payos_payment_link_mocked():
    account = InvestmentAccount(
        account_id=1,
        account_number="ACC100001",
        customer_id=10,
        status="ACTIVE",
    )

    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "code": "00",
        "desc": "success",
        "data": {
            "checkoutUrl": "https://pay.payos.vn/web/test123456",
            "qrCode": "00020101021238...",
            "status": "PENDING",
        },
    }

    with patch("httpx.Client.post", return_value=mock_resp):
        res = create_payos_payment_link(account, Decimal("50000"))
        assert res["account_id"] == 1
        assert res["status"] == "PENDING"
        assert "test123456" in res["checkout_url"]
        assert res["amount"] == Decimal("50000")


def test_process_payos_webhook_credits_account_and_idempotent():
    db = MagicMock()
    account = InvestmentAccount(
        account_id=1,
        account_number="ACC100001",
        customer_id=10,
        cash_balance=Decimal("100000.00"),
        status="ACTIVE",
    )
    db.get.return_value = account

    # First call: no existing notification -> credits balance
    query_mock = MagicMock()
    query_mock.filter.return_value.first.return_value = None
    db.query.return_value = query_mock

    data = {
        "orderCode": 10000000001,  # account_id 1 prefix + 10 digits
        "amount": 50000,
        "description": "NAP 1",
    }
    sorted_parts = ["amount=50000", "description=NAP 1", "orderCode=10000000001"]
    signature = hmac.new(
        settings.PAYOS_CHECKSUM_KEY.encode("utf-8"),
        "&".join(sorted_parts).encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    payload = {"data": data, "signature": signature, "code": "00", "desc": "success"}

    success, msg = process_payos_webhook(db, payload)
    assert success is True
    assert "Nạp thành công" in msg
    assert account.cash_balance == Decimal("150000.00")
    assert db.add.called
    assert db.commit.called

    # Second call (idempotency): notification already exists -> idempotent success
    existing_noti = Notification(
        notification_id=99,
        customer_id=10,
        notification_type="CASH",
        ref_id=10000000001,
        title="Nạp tiền thành công",
        content="...",
    )
    query_mock.filter.return_value.first.return_value = existing_noti
    initial_balance = account.cash_balance

    success_repeat, msg_repeat = process_payos_webhook(db, payload)
    assert success_repeat is True
    assert "Idempotent" in msg_repeat
    assert account.cash_balance == initial_balance


def test_process_payos_webhook_rejects_invalid_signature():
    db = MagicMock()
    payload = {
        "data": {"orderCode": 123, "amount": 10000},
        "signature": "fake_bad_signature",
    }
    with pytest.raises(ValidationException, match="Chữ ký webhook payOS không hợp lệ"):
        process_payos_webhook(db, payload)
