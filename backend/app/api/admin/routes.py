"""Admin API (/admin/v1). Never cached. Every write must also write to audit_log (T06+)."""

from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AdminClaims, public, require
from app.core.config import Settings, get_settings
from app.core.db import get_session
from app.core.permissions import Permission
from app.core.redis import get_redis
from app.core.security import TokenClaims
from app.schemas.auth import AdminChallenge, AdminLoginIn, AdminTotpIn, TokenPair
from app.schemas.newsroom import AdOut, AuditOut, NxtspotOut, OverviewStats, PostListItem, SourceOut
from app.schemas.sources import SourceCreate, SourcePatch, TestFetchOut
from app.services import admin_auth as admin_auth_service
from app.services import newsroom as newsroom_service
from app.services import posts as posts_service
from app.services import sources as sources_service

router = APIRouter(prefix="/admin/v1")


def _ip(request: Request) -> str | None:
    return request.client.host if request.client else None


@router.post("/auth/login", response_model=AdminChallenge, dependencies=[Depends(public)])
async def admin_login(
    body: AdminLoginIn,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AdminChallenge:
    return await admin_auth_service.login(
        session,
        settings,
        get_redis(),
        email=body.email,
        password=body.password,
        ip=_ip(request),
    )


@router.post("/auth/totp", response_model=TokenPair, dependencies=[Depends(public)])
async def admin_totp(
    body: AdminTotpIn,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenPair:
    return await admin_auth_service.verify_second_factor(
        session,
        settings,
        get_redis(),
        challenge_id=body.challenge_id,
        code=body.code,
        ip=_ip(request),
        user_agent=request.headers.get("user-agent"),
    )


@router.get("/me")
async def admin_me(claims: AdminClaims) -> dict[str, object]:
    return {"id": claims.sub, "permissions": list(claims.perms)}


@router.get("/sources", response_model=list[SourceOut])
async def list_sources(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.SOURCES_MANAGE)),  # noqa: B008
) -> list[SourceOut]:
    del claims
    return await newsroom_service.list_sources(session)


@router.post("/sources", response_model=SourceOut)
async def create_source(
    body: SourceCreate,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.SOURCES_MANAGE)),  # noqa: B008
) -> SourceOut:
    return await sources_service.create(session, body, admin_id=UUID(claims.sub), ip=_ip(request))


@router.patch("/sources/{source_id}", response_model=SourceOut)
async def update_source(
    source_id: UUID,
    body: SourcePatch,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.SOURCES_MANAGE)),  # noqa: B008
) -> SourceOut:
    return await sources_service.update(
        session, source_id, body, admin_id=UUID(claims.sub), ip=_ip(request)
    )


@router.post("/sources/{source_id}/test", response_model=TestFetchOut)
async def test_source(
    source_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.SOURCES_MANAGE)),  # noqa: B008
) -> TestFetchOut:
    del claims
    return await sources_service.test_fetch(session, source_id)


@router.get("/posts", response_model=list[PostListItem])
async def list_posts(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.DASHBOARD_VIEW)),  # noqa: B008
    status: Literal["draft", "review", "published", "rejected"] | None = None,
    category: Literal["domestic", "international", "grassroots"] | None = None,
) -> list[PostListItem]:
    del claims
    return await newsroom_service.list_posts(session, status=status, category=category)


@router.post("/posts/{post_id}/publish", response_model=PostListItem)
async def publish_post(
    post_id: UUID,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.POSTS_PUBLISH)),  # noqa: B008
) -> PostListItem:
    return await posts_service.publish(session, post_id, admin_id=UUID(claims.sub), ip=_ip(request))


@router.post("/posts/{post_id}/reject", response_model=PostListItem)
async def reject_post(
    post_id: UUID,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.POSTS_WRITE)),  # noqa: B008
) -> PostListItem:
    return await posts_service.reject(session, post_id, admin_id=UUID(claims.sub), ip=_ip(request))


@router.get("/review", response_model=list[PostListItem])
async def list_review(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.POSTS_WRITE)),  # noqa: B008
) -> list[PostListItem]:
    del claims
    return await newsroom_service.list_review(session)


@router.get("/ads", response_model=list[AdOut])
async def list_ads(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.ADS_MANAGE)),  # noqa: B008
) -> list[AdOut]:
    del claims
    return await newsroom_service.list_ads(session)


@router.get("/audit", response_model=list[AuditOut])
async def list_audit(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.AUDIT_VIEW)),  # noqa: B008
) -> list[AuditOut]:
    del claims
    return await newsroom_service.list_audit(session)


@router.get("/nxtspot", response_model=list[NxtspotOut])
async def list_nxtspot(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.NXTSPOT_CREATE)),  # noqa: B008
) -> list[NxtspotOut]:
    del claims
    return await newsroom_service.list_nxtspot(session)


@router.get("/stats/overview", response_model=OverviewStats)
async def stats_overview(
    session: Annotated[AsyncSession, Depends(get_session)],
    claims: TokenClaims = Depends(require(Permission.DASHBOARD_VIEW)),  # noqa: B008
) -> OverviewStats:
    del claims
    return await newsroom_service.overview(session)
