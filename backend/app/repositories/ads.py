from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AdCampaign


async def list_all(session: AsyncSession) -> list[AdCampaign]:
    stmt = select(AdCampaign).order_by(AdCampaign.start_at.desc())
    return list((await session.scalars(stmt)).all())


async def list_active(session: AsyncSession) -> list[AdCampaign]:
    stmt = select(AdCampaign).where(AdCampaign.is_active.is_(True))
    return list((await session.scalars(stmt)).all())
