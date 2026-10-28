from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Source


async def list_all(session: AsyncSession) -> list[Source]:
    stmt = select(Source).order_by(Source.priority.desc(), Source.name)
    return list((await session.scalars(stmt)).all())


async def get_by_name(session: AsyncSession, name: str) -> Source | None:
    return await session.scalar(select(Source).where(Source.name == name))
