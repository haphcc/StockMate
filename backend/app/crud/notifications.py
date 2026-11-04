"""Owner: TV5 - Tuệ.

CRUD database operations for Notifications.
"""

from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.models.notification import Notification


def get_notification_by_id(db: Session, notification_id: int) -> Notification | None:
    """Fetch single notification by ID."""
    return db.query(Notification).filter(Notification.notification_id == notification_id).first()


def get_notifications_by_customer(
    db: Session,
    customer_id: int,
    unread_only: bool = False,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[Notification], int]:
    """Fetch paginated notifications for customer sorted by timestamp DESC then ID DESC."""
    query = db.query(Notification).filter(Notification.customer_id == customer_id)

    if unread_only:
        query = query.filter(Notification.is_read.is_(False))

    total = query.count()
    items = (
        query.order_by(desc(Notification.created_at), desc(Notification.notification_id))
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return items, total


def mark_notification_as_read(
    db: Session, notification_id: int, customer_id: int
) -> Notification | None:
    """Mark notification as read for the customer."""
    notif = (
        db.query(Notification)
        .filter(
            Notification.notification_id == notification_id,
            Notification.customer_id == customer_id,
        )
        .first()
    )
    if not notif:
        return None

    if not notif.is_read:
        notif.is_read = True
        db.commit()
        db.refresh(notif)
    return notif
