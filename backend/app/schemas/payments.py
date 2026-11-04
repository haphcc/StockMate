"""Owner: TV1 - Phuoc.

Schemas for payOS VietQR deposit and webhook notification.
"""

from decimal import Decimal
from typing import Any

from pydantic import BaseModel, Field

from app.schemas.common import Money


class DepositRequest(BaseModel):
    amount: Decimal = Field(..., gt=0, description="Số tiền nạp (VND), phải lớn hơn 0")
    return_url: str | None = Field(
        default=None, description="URL chuyển hướng khi thanh toán thành công"
    )
    cancel_url: str | None = Field(default=None, description="URL chuyển hướng khi hủy thanh toán")


class DepositResponse(BaseModel):
    order_code: int
    checkout_url: str
    qr_code: str
    status: str
    account_id: int
    amount: Money


class PayOSWebhookRequest(BaseModel):
    code: str
    desc: str
    data: dict[str, Any]
    signature: str


class PayOSWebhookResponse(BaseModel):
    success: bool
    message: str | None = None
