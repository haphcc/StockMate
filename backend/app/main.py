"""Owner: TV4 - LB / TV1 - Phuoc.

FastAPI application entry point, CORS middleware, and route mounting.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.api import api_router
from app.api.v1.endpoints import health
from app.core.config import settings
from app.core.errors import register_error_handlers

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for StockMate Exchange - Trading, Market Data, and Admin Portal",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)
register_error_handlers(app)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount root health endpoints (/health/live, /health/ready) as per contract
app.include_router(health.router, prefix="/health", tags=["health"])

# Mount API routes (/api/auth/..., /api/admin/..., etc.)
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.get("/", tags=["root"])
def root() -> dict[str, str]:
    """Root endpoint verifying API server is online."""
    return {
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "status": "online",
        "docs_url": "/docs",
    }
