"""Owner: TV5 - Tuệ. Contract stub; follow docs/team/ and docs/API_CONTRACT.md."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query

from app.api.deps import require_user
from app.core.errors import not_implemented
from app.schemas.common import ERROR_RESPONSES, Page
from app.schemas.notifications import NotificationResponse

router = APIRouter(
    tags=["notifications"], responses=ERROR_RESPONSES, dependencies=[Depends(require_user)]
)


@router.get("/notifications", response_model=Page[NotificationResponse], status_code=200)
def notifications(
    unread: bool = False,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    not_implemented("notifications", "TV5 - Tuệ")


@router.post(
    "/notifications/{notification_id}/read", response_model=NotificationResponse, status_code=200
)
def read_notification(
    notification_id: Annotated[int, Path(gt=0)],
):
    not_implemented("read_notification", "TV5 - Tuệ")
