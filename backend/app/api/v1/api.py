from fastapi import APIRouter

from app.api.v1.endpoints import (
    accounts,
    auth,
    market,
    notifications,
    orders,
    transactions,
    watchlist,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(market.router)
api_router.include_router(accounts.router)
api_router.include_router(orders.router)
api_router.include_router(transactions.router)
api_router.include_router(watchlist.router)
api_router.include_router(notifications.router)
