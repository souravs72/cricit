"""Issue and rotate access/refresh pairs. All SQL goes through repositories.sessions."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import Unauthorized
from app.core.security import (
    PrincipalType,
    hash_refresh_token,
    issue_access_token,
    new_refresh_token,
)
from app.models import Session
from app.repositories import sessions as sessions_repo
from app.schemas.auth import TokenPair


def _sliding_expiry(settings: Settings, typ: PrincipalType, now: datetime) -> datetime:
    if typ == "admin":
        return now + timedelta(minutes=settings.admin_session_idle_min)
    return now + timedelta(days=settings.user_session_sliding_days)


def _absolute_expiry(settings: Settings, typ: PrincipalType, now: datetime) -> datetime:
    if typ == "admin":
        return now + timedelta(hours=settings.admin_session_absolute_h)
    return now + timedelta(days=settings.user_session_absolute_days)


async def open_session(
    db: AsyncSession,
    settings: Settings,
    *,
    typ: PrincipalType,
    principal_id: str,
    permissions: tuple[str, ...] = (),
    device_id: str | None = None,
    user_agent: str | None = None,
) -> TokenPair:
    now = datetime.now(UTC)
    refresh, refresh_hash = new_refresh_token()
    row = Session(
        principal_type=typ,
        principal_id=UUID(principal_id),
        family_id=uuid4(),
        refresh_hash=refresh_hash,
        device_id=device_id,
        user_agent=user_agent,
        expires_at=_sliding_expiry(settings, typ, now),
        absolute_expires_at=_absolute_expiry(settings, typ, now),
    )
    await sessions_repo.insert(db, row)
    access = issue_access_token(
        settings,
        subject=principal_id,
        session_id=str(row.id),
        typ=typ,
        permissions=permissions,
    )
    ttl = settings.admin_access_ttl_s if typ == "admin" else settings.user_access_ttl_s
    return TokenPair(access_token=access, refresh_token=refresh, expires_in=ttl)


async def rotate_refresh(
    db: AsyncSession,
    settings: Settings,
    presented: str,
    *,
    permissions: tuple[str, ...] = (),
) -> TokenPair:
    now = datetime.now(UTC)
    digest = hash_refresh_token(presented)
    row = await sessions_repo.get_by_refresh_hash(db, digest)
    if row is None:
        reused = await sessions_repo.get_by_previous_hash(db, digest)
        if reused is not None:
            await sessions_repo.revoke_family(db, reused.family_id, now=now, reason="reuse")
            await db.commit()
            raise Unauthorized("Session revoked")
        raise Unauthorized("Invalid refresh token")
    if row.revoked_at is not None:
        raise Unauthorized("Session revoked")
    if now >= row.absolute_expires_at or now >= row.expires_at:
        await sessions_repo.revoke_sid(db, row.id, now=now, reason="expired")
        await db.commit()
        raise Unauthorized("Session expired")
    refresh, new_hash = new_refresh_token()
    await sessions_repo.rotate(
        db,
        row,
        new_hash=new_hash,
        expires_at=_sliding_expiry(settings, row.principal_type, now),  # type: ignore[arg-type]
    )
    resolved = permissions
    if not resolved and row.principal_type == "admin":
        from app.core.permissions import Role, permissions_for
        from app.repositories import admins as admins_repo

        admin = await admins_repo.get_by_id(db, row.principal_id)
        if admin is None or not admin.is_active:
            raise Unauthorized("Session revoked")
        resolved = tuple(p.value for p in permissions_for(Role(admin.role)))
    access = issue_access_token(
        settings,
        subject=str(row.principal_id),
        session_id=str(row.id),
        typ=row.principal_type,  # type: ignore[arg-type]
        permissions=resolved,
    )
    ttl = (
        settings.admin_access_ttl_s if row.principal_type == "admin" else settings.user_access_ttl_s
    )
    return TokenPair(access_token=access, refresh_token=refresh, expires_in=ttl)


async def logout(db: AsyncSession, session_id: str) -> None:
    await sessions_repo.revoke_sid(db, UUID(session_id), now=datetime.now(UTC), reason="logout")
