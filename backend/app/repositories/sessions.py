"""SQL for login sessions. Refresh tokens are stored as SHA-256 hashes only."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Session


async def insert(session: AsyncSession, row: Session) -> Session:
    session.add(row)
    await session.flush()
    return row


async def get_by_refresh_hash(session: AsyncSession, refresh_hash: str) -> Session | None:
    return await session.scalar(select(Session).where(Session.refresh_hash == refresh_hash))


async def get_by_previous_hash(session: AsyncSession, previous_hash: str) -> Session | None:
    return await session.scalar(select(Session).where(Session.previous_hash == previous_hash))


async def get_by_id(session: AsyncSession, session_id: uuid.UUID) -> Session | None:
    return await session.get(Session, session_id)


async def rotate(
    session: AsyncSession,
    row: Session,
    *,
    new_hash: str,
    expires_at: datetime,
) -> None:
    row.previous_hash = row.refresh_hash
    row.refresh_hash = new_hash
    row.expires_at = expires_at


async def revoke_family(
    session: AsyncSession,
    family_id: uuid.UUID,
    *,
    now: datetime,
    reason: str,
) -> None:
    await session.execute(
        update(Session)
        .where(Session.family_id == family_id, Session.revoked_at.is_(None))
        .values(revoked_at=now, revoked_reason=reason)
    )


async def revoke_sid(
    session: AsyncSession,
    session_id: uuid.UUID,
    *,
    now: datetime,
    reason: str,
) -> None:
    row = await get_by_id(session, session_id)
    if row is None or row.revoked_at is not None:
        return
    row.revoked_at = now
    row.revoked_reason = reason
