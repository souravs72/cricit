"""FastAPI auth dependencies.

Every route must declare exactly one of these (tests/test_route_auth.py enforces it):
- `public`            -> no login needed (feeds, config, health)
- `optional_user`     -> works logged out; user attached when a valid token is sent
- `current_user`      -> app user required
- `current_admin`     -> any signed-in admin
- `require(Permission.X)` -> admin with that permission

Session revocation (logout, refresh-token reuse) is checked against Redis in the
service layer in ticket T05/T06; this module only verifies the token itself.
"""

from collections.abc import Callable
from typing import Annotated, Any

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import Settings, get_settings
from app.core.errors import Forbidden, Unauthorized
from app.core.permissions import Permission
from app.core.security import TokenClaims, decode_access_token

AUTH_MARKER = "__cricit_auth__"
_bearer = HTTPBearer(auto_error=False)


def _mark(fn: Callable[..., Any]) -> Callable[..., Any]:
    setattr(fn, AUTH_MARKER, True)
    return fn


@_mark
async def public() -> None:
    """Explicit opt-out of authentication. Use only for content every visitor may see."""


@_mark
async def optional_user(
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenClaims | None:
    if creds is None:
        return None
    return decode_access_token(settings, creds.credentials, expected="user")


@_mark
async def current_user(
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenClaims:
    if creds is None:
        raise Unauthorized("Sign in to continue")
    return decode_access_token(settings, creds.credentials, expected="user")


@_mark
async def current_admin(
    request: Request,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenClaims:
    # The admin's Next.js server forwards the token as a bearer header; browsers never hold it.
    if creds is None:
        raise Unauthorized("Admin sign-in required")
    claims = decode_access_token(settings, creds.credentials, expected="admin")
    request.state.admin_id = claims.sub
    return claims


def require(permission: Permission) -> Callable[..., Any]:
    @_mark
    async def _check(claims: Annotated[TokenClaims, Depends(current_admin)]) -> TokenClaims:
        if permission.value not in claims.perms:
            raise Forbidden(f"Missing permission: {permission.value}")
        return claims

    _check.__name__ = f"require_{permission.name.lower()}"
    return _check


UserClaims = Annotated[TokenClaims, Depends(current_user)]
OptionalUser = Annotated[TokenClaims | None, Depends(optional_user)]
AdminClaims = Annotated[TokenClaims, Depends(current_admin)]
