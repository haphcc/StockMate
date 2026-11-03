"""Owner: TV5 - Tuệ.

Order endpoints for placing, listing, and canceling orders.
Conforms strictly to API_CONTRACT.md.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.customer import Customer
from app.schemas.trading import CreateOrderRequest, OrderResponse, Page
from app.services.order_service import (
    build_order_response,
    cancel_order,
    list_account_orders,
    place_order,
)

router = APIRouter()


@router.post(
    "/accounts/{account_id}/orders",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đặt lệnh mua hoặc bán cổ phiếu",
)
def create_order_endpoint(
    account_id: int,
    req: CreateOrderRequest,
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> OrderResponse:
    """Place a new LO stock order with idempotency check and fund/share reservation."""
    order, _ = place_order(
        db=db,
        customer=current_user,
        account_id=account_id,
        req=req,
    )
    return build_order_response(order)


@router.get(
    "/accounts/{account_id}/orders",
    response_model=Page[OrderResponse],
    summary="Tra cứu sổ lệnh của tài khoản",
)
def get_orders_endpoint(
    account_id: int,
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    status: str | None = Query(default=None, description="Lọc theo trạng thái lệnh"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[OrderResponse]:
    """Retrieve paginated orders for account sorted by timestamp DESC then ID DESC."""
    return list_account_orders(
        db=db,
        customer=current_user,
        account_id=account_id,
        status=status,
        page=page,
        page_size=page_size,
    )


@router.delete(
    "/orders/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Hủy lệnh chờ khớp",
)
def cancel_order_endpoint(
    order_id: int,
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> OrderResponse:
    """Cancel a pending order and release reserved funds or blocked shares."""
    cancelled = cancel_order(
        db=db,
        customer=current_user,
        order_id=order_id,
    )
    return build_order_response(cancelled)
