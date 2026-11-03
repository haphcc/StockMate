"""Owner: TV5 - Tuệ.

Transaction endpoints for viewing trade history.
Conforms strictly to API_CONTRACT.md.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.customer import Customer
from app.schemas.trading import Page, TransactionResponse
from app.services.order_service import list_account_transactions

router = APIRouter()


@router.get(
    "/accounts/{account_id}/transactions",
    response_model=Page[TransactionResponse],
    summary="Xem lịch sử giao dịch khớp lệnh của tài khoản",
)
def get_account_transactions_endpoint(
    account_id: int,
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[TransactionResponse]:
    """Retrieve paginated trade history sorted by timestamp DESC then ID DESC."""
    return list_account_transactions(
        db=db,
        customer=current_user,
        account_id=account_id,
        page=page,
        page_size=page_size,
    )
