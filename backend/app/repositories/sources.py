"""SQL for sources. Callers: services.sources, services.ingest, services.newsroom.

API: GET/POST/PATCH /admin/v1/sources, worker fetch_due_sources.
Schema: Source rows. User: "Check what is tobe built now into this - build it"
"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Source


async def list_all(session: AsyncSession) -> list[Source]:
    stmt = select(Source).order_by(Source.priority.desc(), Source.name)
    return list((await session.scalars(stmt)).all())


async def list_active_rss(session: AsyncSession) -> list[Source]:
    stmt = select(Source).where(Source.is_active.is_(True), Source.adapter == "rss")
    return list((await session.scalars(stmt)).all())


async def get(session: AsyncSession, source_id: UUID) -> Source | None:
    return await session.get(Source, source_id)


async def get_by_name(session: AsyncSession, name: str) -> Source | None:
    return await session.scalar(select(Source).where(Source.name == name))
