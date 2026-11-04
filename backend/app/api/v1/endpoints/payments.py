"""Owner: TV1 - Phuoc.

PayOS VietQR webhook endpoint for automated balance crediting.
"""

from fastapi import APIRouter

from app.api.deps import DbDep
from app.schemas.payments import PayOSWebhookRequest, PayOSWebhookResponse
from app.services.payment_service import process_payos_webhook

router = APIRouter()


@router.post("/payos/webhook", response_model=PayOSWebhookResponse)
def payos_webhook(
    payload: PayOSWebhookRequest,
    db: DbDep,
) -> PayOSWebhookResponse:
    """Public webhook receiver for payOS payment status notifications."""
    success, message = process_payos_webhook(db, payload.model_dump())
    return PayOSWebhookResponse(success=success, message=message)
