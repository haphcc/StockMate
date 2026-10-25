"""Owner: TV5 - Tuệ. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.common import ERROR_RESPONSES, OrderStatus, Page
from app.schemas.trading import CreateOrderRequest, OrderResponse

router = APIRouter(tags=["orders"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)])


@router.get("/accounts/{account_id}/orders", response_model=Page[OrderResponse], status_code=200)
def orders(
    account_id: Annotated[int, Path(gt=0)],
    status: OrderStatus | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    not_implemented("orders", "TV5 - Tuệ")


@router.post("/accounts/{account_id}/orders", response_model=OrderResponse, status_code=201)
def create_order(
    account_id: Annotated[int, Path(gt=0)],
    payload: CreateOrderRequest,
):
    not_implemented("create_order", "TV5 - Tuệ")


@router.delete("/orders/{order_id}", response_model=OrderResponse, status_code=200)
def cancel_order(
    order_id: Annotated[int, Path(gt=0)],
):
    not_implemented("cancel_order", "TV5 - Tuệ")
