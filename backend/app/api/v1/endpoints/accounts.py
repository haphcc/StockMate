"""Owner: TV4 - LB. Only expose accounts owned by the authenticated customer."""

from fastapi import APIRouter
from sqlalchemy import select

from app.api.deps import CurrentUserDep, DbDep
from app.models.investment_account import InvestmentAccount
from app.schemas.accounts import AccountResponse

router = APIRouter()


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
