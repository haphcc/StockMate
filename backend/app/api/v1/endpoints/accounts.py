"""Owner: TV4 - LB. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.accounts import AccountResponse, AssetResponse, PortfolioResponse
from app.schemas.common import ERROR_RESPONSES

router = APIRouter(
    tags=["accounts"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)]
)


@router.get("/accounts", response_model=list[AccountResponse], status_code=200)
def accounts():
    not_implemented("accounts", "TV4 - LB")


@router.get("/accounts/{account_id}/assets", response_model=AssetResponse, status_code=200)
def assets(
    account_id: Annotated[int, Path(gt=0)],
):
    not_implemented("assets", "TV4 - LB")


@router.get(
    "/accounts/{account_id}/portfolio", response_model=list[PortfolioResponse], status_code=200
)
def portfolio(
    account_id: Annotated[int, Path(gt=0)],
):
    not_implemented("portfolio", "TV4 - LB")
