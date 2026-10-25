from typing import Annotated, NoReturn

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.errors import not_implemented

bearer = HTTPBearer(auto_error=False)


def require_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> NoReturn:
    if credentials is None:
        raise HTTPException(
            status_code=401,
            headers={"WWW-Authenticate": "Bearer"},
            detail={"code": "UNAUTHORIZED", "message": "Cần đăng nhập.", "details": {}},
        )
    # A supplied token is never treated as valid by the scaffold.
    not_implemented("verify_access_token", "TV4 - LB")
