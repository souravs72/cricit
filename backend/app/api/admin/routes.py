"""Admin API (/admin/v1). Never cached. Every write must also write to audit_log (T06+)."""

from fastapi import APIRouter, Depends

from app.api.v1.routes import NotBuiltYet
from app.core.auth import AdminClaims, public, require
from app.core.permissions import Permission
from app.core.security import TokenClaims
from app.schemas.auth import AdminChallenge, AdminLoginIn, AdminTotpIn, TokenPair

router = APIRouter(prefix="/admin/v1")


@router.post("/auth/login", response_model=AdminChallenge, dependencies=[Depends(public)])
async def admin_login(body: AdminLoginIn) -> AdminChallenge:
    raise NotBuiltYet("T06: verify Argon2id hash, lockout after 5 failures, return TOTP challenge")


@router.post("/auth/totp", response_model=TokenPair, dependencies=[Depends(public)])
async def admin_totp(body: AdminTotpIn) -> TokenPair:
    raise NotBuiltYet("T06: verify TOTP or recovery code, open admin session, issue tokens")


@router.get("/me")
async def admin_me(claims: AdminClaims) -> dict[str, object]:
    return {"id": claims.sub, "permissions": list(claims.perms)}


@router.get("/sources")
async def list_sources(
    claims: TokenClaims = Depends(require(Permission.SOURCES_MANAGE)),  # noqa: B008
) -> list[dict[str, object]]:
    raise NotBuiltYet("T09: list sources with health status")
