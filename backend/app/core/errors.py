"""Owner: TV4 - LB / TV1 - Phuoc.

Application error classes and standardized error response helpers.
"""

from typing import Any

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import DBAPIError
from starlette.exceptions import HTTPException as StarletteHTTPException


def register_error_handlers(app: FastAPI) -> None:
    """Expose the agreed error envelope without request secrets or DB internals."""

    @app.exception_handler(AppException)
    async def app_error(_: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content=exc.detail, headers=exc.headers)

    @app.exception_handler(RequestValidationError)
    async def validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        details = {
            "fields": [
                {"loc": list(error["loc"]), "message": error["msg"], "type": error["type"]}
                for error in exc.errors()
            ]
        }
        return JSONResponse(
            status_code=422,
            content={
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Dữ liệu không hợp lệ.",
                    "details": details,
                }
            },
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_error(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            headers=exc.headers,
            content={
                "error": {
                    "code": "NOT_FOUND" if exc.status_code == 404 else "HTTP_ERROR",
                    "message": str(exc.detail),
                    "details": {},
                }
            },
        )

    @app.exception_handler(DBAPIError)
    async def database_error(_: Request, exc: DBAPIError) -> JSONResponse:
        return JSONResponse(
            status_code=503,
            content={
                "error": {
                    "code": "DATABASE_UNAVAILABLE",
                    "message": "Không thể truy cập cơ sở dữ liệu.",
                    "details": {},
                }
            },
        )


class AppException(HTTPException):
    """Base application exception returning standardized API error format."""

    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(
            status_code=status_code,
            detail={
                "error": {
                    "code": code,
                    "message": message,
                    "details": details or {},
                }
            },
        )


class UnauthorizedException(AppException):
    """401 Unauthorized exception."""

    def __init__(
        self,
        message: str = "Yêu cầu đăng nhập để truy cập tài nguyên này.",
        code: str = "UNAUTHORIZED",
    ) -> None:
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED, code=code, message=message)


class ForbiddenException(AppException):
    """403 Forbidden exception."""

    def __init__(
        self, message: str = "Bạn không có quyền thực hiện thao tác này.", code: str = "FORBIDDEN"
    ) -> None:
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, code=code, message=message)


class NotFoundException(AppException):
    """404 Not Found exception."""

    def __init__(
        self, message: str = "Không tìm thấy dữ liệu yêu cầu.", code: str = "NOT_FOUND"
    ) -> None:
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, code=code, message=message)


class ConflictException(AppException):
    """409 Conflict exception."""

    def __init__(self, message: str, code: str = "CONFLICT") -> None:
        super().__init__(status_code=status.HTTP_409_CONFLICT, code=code, message=message)


class ValidationException(AppException):
    """422 Validation exception."""

    def __init__(
        self, message: str, code: str = "VALIDATION_ERROR", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            code=code,
            message=message,
            details=details,
        )
