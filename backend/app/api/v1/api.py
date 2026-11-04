"""Owner: TV4 - LB / TV1 - Phuoc / TV5 - Tuệ.

API v1 main router aggregating all sub-routers.
"""

from fastapi import APIRouter

from app.api.v1.endpoints import accounts, admin, auth, health, notifications, orders, transactions
from app.schemas.common import ErrorResponse

api_router = APIRouter(
    responses={code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 422, 503)}
)

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(accounts.router, prefix="/accounts", tags=["accounts"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(orders.router, tags=["orders"])
api_router.include_router(transactions.router, tags=["transactions"])
api_router.include_router(notifications.router, tags=["notifications"])
