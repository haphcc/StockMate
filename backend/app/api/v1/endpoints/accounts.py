"""Owner: TV4 - LB / TV1 - Phuoc.

Account endpoints: balances, portfolio, assets, and VietQR deposit via payOS.
"""

from typing import Annotated

from fastapi import APIRouter, Path, status
from sqlalchemy import select

from app.api.deps import CurrentUserDep, DbDep
from app.core.errors import NotFoundException, ValidationException
from app.models.investment_account import InvestmentAccount
from app.schemas.accounts import AccountResponse, AssetResponse, PortfolioResponse
from app.schemas.payments import DepositRequest, DepositResponse
from app.services import account_service
from app.services.payment_service import create_payos_payment_link

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


@router.post(
    "/{account_id}/deposit", response_model=DepositResponse, status_code=status.HTTP_201_CREATED
)
def deposit(
    account_id: AccountId,
    payload: DepositRequest,
    current_user: CurrentUserDep,
    db: DbDep,
) -> DepositResponse:
    """Create a VietQR deposit payment link via payOS (TV1 - Phuoc)."""
    account = db.get(InvestmentAccount, account_id)
    if not account or account.customer_id != current_user.customer_id:
        raise NotFoundException("Không tìm thấy tài khoản.")
    if account.status != "ACTIVE":
        raise ValidationException("Tài khoản không ở trạng thái hoạt động.")

    data = create_payos_payment_link(
        account=account,
        amount=payload.amount,
        return_url=payload.return_url,
        cancel_url=payload.cancel_url,
    )
    return DepositResponse(**data)
