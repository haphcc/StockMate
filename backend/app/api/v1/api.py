"""Owner: TV4 - LB / TV1 - Phuoc.

API v1 main router aggregating all sub-routers.
"""

from fastapi import APIRouter

from app.api.v1.endpoints import admin, auth, health

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(health.router, prefix="/health", tags=["health"])
