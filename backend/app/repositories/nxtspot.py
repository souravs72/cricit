"""SQL for grassroots submissions. Called by newsroom.list_nxtspot → GET /admin/v1/nxtspot."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import NxtspotSubmission


async def list_recent(session: AsyncSession, *, limit: int = 50) -> list[NxtspotSubmission]:
    stmt = select(NxtspotSubmission).order_by(NxtspotSubmission.created_at.desc()).limit(limit)
    return list((await session.scalars(stmt)).all())
