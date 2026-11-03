"""Owner: TV5 - Tuệ.

Business logic service for customer notifications.
"""

from sqlalchemy.orm import Session

from app.crud.notifications import (
    get_notifications_by_customer,
    mark_notification_as_read,
)
from app.models.notification import Notification
from app.schemas.notifications import NotificationResponse
from app.schemas.trading import Page


def send_notification(
    db: Session,
    customer_id: int,
    title: str,
    content: str,
    notification_type: str = "SYSTEM",
    ref_id: int | None = None,
) -> Notification:
    """Create and persist a notification record."""
    notif = Notification(
        customer_id=customer_id,
        title=title,
        content=content,
        notification_type=notification_type,
        ref_id=ref_id,
        is_read=False,
    )
    db.add(notif)
    # Note: caller commits as part of the overall transaction
    return notif


def get_customer_notifications(
    db: Session,
    customer_id: int,
    unread_only: bool = False,
    page: int = 1,
    page_size: int = 20,
) -> Page[NotificationResponse]:
    """Retrieve paginated notifications for customer."""
    items, total = get_notifications_by_customer(
        db=db,
        customer_id=customer_id,
        unread_only=unread_only,
        page=page,
        page_size=page_size,
    )
    return Page(
        items=[NotificationResponse.model_validate(n) for n in items],
        page=page,
        page_size=page_size,
        total=total,
    )


def read_customer_notification(
    db: Session,
    customer_id: int,
    notification_id: int,
) -> NotificationResponse | None:
    """Mark notification as read; return None if not found or unauthorized."""
    notif = mark_notification_as_read(
        db=db,
        notification_id=notification_id,
        customer_id=customer_id,
    )
    if not notif:
        return None
    return NotificationResponse.model_validate(notif)
