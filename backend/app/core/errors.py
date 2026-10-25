from typing import NoReturn

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


def not_implemented(operation: str, owner: str) -> NoReturn:
    raise HTTPException(
        status_code=501,
        detail={
            "code": "NOT_IMPLEMENTED",
            "message": "Endpoint mới có hợp đồng dữ liệu; chưa có xử lý nghiệp vụ.",
            "details": {"operation": operation, "owner": owner},
        },
    )


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        detail = exc.detail
        error = (
            detail
            if isinstance(detail, dict)
            else {"code": f"HTTP_{exc.status_code}", "message": str(detail), "details": {}}
        )
        return JSONResponse(
            status_code=exc.status_code, content={"error": error}, headers=exc.headers
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
        # Do not echo submitted passwords or tokens into errors/logs.
        issues = [{"location": list(e["loc"]), "type": e["type"]} for e in exc.errors()]
        return JSONResponse(
            status_code=422,
            content={
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Dữ liệu gửi lên không hợp lệ.",
                    "details": {"issues": issues},
                }
            },
        )
