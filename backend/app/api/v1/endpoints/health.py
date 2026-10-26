"""Owner: TV4 - LB / TV1 - Phuoc.

Health check endpoints for application and database readiness probes.
"""

import sqlalchemy as sa
from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.api.deps import get_db

router = APIRouter()


@router.get("/live")
def live_check() -> dict[str, str]:
    """Process liveness probe."""
    return {"status": "ok"}


@router.get("/ready")
def ready_check(db: Session = Depends(get_db)) -> JSONResponse:
    """Database and dependency readiness probe."""
    try:
        db.execute(sa.text("SELECT 1"))
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"status": "ready", "database": "connected"},
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "error", "message": "Database unavailable", "details": str(e)},
        )
