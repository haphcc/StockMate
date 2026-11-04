"""Owner: TV4 - LB. Only expose accounts owned by the authenticated customer."""

from typing import Annotated

from fastapi import APIRouter, Path
from sqlalchemy import select

from app.api.deps import CurrentUserDep, DbDep
from app.models.investment_account import InvestmentAccount
from app.schemas.accounts import AccountResponse, AssetResponse, PortfolioResponse
from app.services import account_service

router = APIRouter()
AccountId = Annotated[int, Path(ge=1, le=9223372036854775807)]


@router.get("", response_model=list[AccountResponse])
def list_accounts(current_user: CurrentUserDep, db: DbDep) -> list[InvestmentAccount]:
    return list(
        db.scalars(
            select(InvestmentAccount)
            .where(
                InvestmentAccount.customer_id == current_user.customer_id,
            )
            .order_by(InvestmentAccount.account_id)
        )
    )


@router.get("/{account_id}/assets", response_model=AssetResponse)
def assets(account_id: AccountId, current_user: CurrentUserDep, db: DbDep) -> AssetResponse:
    return account_service.assets(db, current_user.customer_id, account_id)


@router.get("/{account_id}/portfolio", response_model=list[PortfolioResponse])
def portfolio(
    account_id: AccountId,
    current_user: CurrentUserDep,
    db: DbDep,
) -> list[PortfolioResponse]:
    return account_service.portfolio(db, current_user.customer_id, account_id)
