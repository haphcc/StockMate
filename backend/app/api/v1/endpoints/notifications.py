"""Owner: TV5 - Tuệ.

Customer notifications endpoints.
Conforms strictly to API_CONTRACT.md.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.errors import NotFoundException
from app.db.session import get_db
from app.models.customer import Customer
from app.schemas.notifications import NotificationResponse
from app.schemas.trading import Page
from app.services.notification_service import (
    get_customer_notifications,
    read_customer_notification,
)

router = APIRouter()


@router.get(
    "/notifications",
    response_model=Page[NotificationResponse],
    summary="Xem danh sách thông báo của khách hàng",
)
def get_notifications_endpoint(
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    unread: bool = Query(default=False, description="Chỉ lấy thông báo chưa đọc"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[NotificationResponse]:
    """Retrieve paginated notifications sorted by timestamp DESC then ID DESC."""
    return get_customer_notifications(
        db=db,
        customer_id=current_user.customer_id,
        unread_only=unread,
        page=page,
        page_size=page_size,
    )


@router.post(
    "/notifications/{notification_id}/read",
    response_model=NotificationResponse,
    summary="Đánh dấu thông báo đã đọc",
)
def mark_notification_read_endpoint(
    notification_id: int,
    current_user: Annotated[Customer, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> NotificationResponse:
    """Mark notification as read; calling again still returns 200."""
    result = read_customer_notification(
        db=db,
        customer_id=current_user.customer_id,
        notification_id=notification_id,
    )
    if not result:
        raise NotFoundException(
            message="Không tìm thấy thông báo hoặc bạn không có quyền truy cập.",
            code="NOTIFICATION_NOT_FOUND",
        )
    return result
