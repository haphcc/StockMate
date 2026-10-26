"""Owner: TV4 - LB / TV1 - Phuoc.

Application error classes and standardized error response helpers.
"""

from typing import Any

from fastapi import HTTPException, status


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
