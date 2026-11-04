"""Owner: TV5 - Tuệ.

Pydantic schemas for Customer Notifications.
Conforms strictly to API_CONTRACT.md.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    """Schema for customer notification message."""

    model_config = ConfigDict(from_attributes=True)

    notification_id: int
    title: str
    content: str
    notification_type: str
    ref_id: int | None = None
    is_read: bool
    created_at: datetime
