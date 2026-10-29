from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AdCampaign, AdStatsDaily


async def list_all(session: AsyncSession) -> list[AdCampaign]:
    stmt = select(AdCampaign).order_by(AdCampaign.start_at.desc())
    return list((await session.scalars(stmt)).all())


async def list_active(session: AsyncSession) -> list[AdCampaign]:
    stmt = select(AdCampaign).where(AdCampaign.is_active.is_(True))
    return list((await session.scalars(stmt)).all())


async def list_live(session: AsyncSession, *, now: datetime) -> list[AdCampaign]:
    stmt = (
        select(AdCampaign)
        .where(
            AdCampaign.is_active.is_(True),
            AdCampaign.start_at <= now,
            AdCampaign.end_at > now,
            AdCampaign.format.in_(("sponsored_card", "full_page")),
        )
        .order_by(AdCampaign.start_at.desc())
    )
    return list((await session.scalars(stmt)).all())


async def add_daily_stats(
    session: AsyncSession,
    campaign_id: uuid.UUID,
    day: date,
    *,
    impressions: int = 0,
    clicks: int = 0,
) -> None:
    stmt = pg_insert(AdStatsDaily).values(
        campaign_id=campaign_id,
        day=day,
        impressions=impressions,
        clicks=clicks,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=["campaign_id", "day"],
        set_={
            "impressions": AdStatsDaily.impressions + stmt.excluded.impressions,
            "clicks": AdStatsDaily.clicks + stmt.excluded.clicks,
        },
    )
    await session.execute(stmt)


async def stats_on_day(session: AsyncSession, day: date) -> dict[uuid.UUID, AdStatsDaily]:
    stmt = select(AdStatsDaily).where(AdStatsDaily.day == day)
    return {row.campaign_id: row for row in (await session.scalars(stmt)).all()}
