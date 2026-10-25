from typing import Literal

from pydantic import AwareDatetime

from app.schemas.common import ContractModel


class NotificationResponse(ContractModel):
    notification_id: int
    title: str
    content: str
    notification_type: Literal["ORDER", "TRANSACTION", "PRICE_ALERT", "CASH", "SYSTEM", "NEWS"]
    ref_id: int | None
    is_read: bool
    created_at: AwareDatetime
