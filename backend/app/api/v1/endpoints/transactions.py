"""Owner: TV5 - Tuệ. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.common import ERROR_RESPONSES, Page
from app.schemas.trading import TransactionResponse

router = APIRouter(
    tags=["transactions"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)]
)


@router.get(
    "/accounts/{account_id}/transactions", response_model=Page[TransactionResponse], status_code=200
)
def transactions(
    account_id: Annotated[int, Path(gt=0)],
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    not_implemented("transactions", "TV5 - Tuệ")
