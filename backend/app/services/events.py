"""Redis counters for reader events; hourly rollup into daily tables (T26).

Callers: POST /v1/events, workers.rollup_stats, tests/test_events.py.
Never stores raw event rows.
User: "audit the changes and implement more features and build the changes"
"""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any
from uuid import UUID

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories import ads as ads_repo
from app.repositories import posts as posts_repo
from app.schemas.events import EventIn

DIRTY = "ev:dirty"
LOCK = "ev:rollup-lock"
TTL_S = 3 * 24 * 3600
POST_METRICS = {"view": "views", "open": "opens", "share": "shares", "bookmark": "bookmarks"}
AD_METRICS = {"ad_impression": "impressions", "ad_click": "clicks"}
POST_COLS = frozenset(POST_METRICS.values())
AD_COLS = frozenset(AD_METRICS.values())


def counter_key(event: EventIn, *, now: datetime) -> str | None:
    clock = now if now.tzinfo else now.replace(tzinfo=UTC)
    clock = clock.astimezone(UTC)
    when = event.occurred_at or clock
    if when.tzinfo is None:
        when = when.replace(tzinfo=UTC)
    when = when.astimezone(UTC)
    if abs((when - clock).total_seconds()) > TTL_S:
        when = clock
    day = when.date().isoformat()
    if event.name in POST_METRICS and event.post_id is not None:
        return f"ev:p:{event.post_id}:{day}:{POST_METRICS[event.name]}"
    if event.name in AD_METRICS and event.campaign_id is not None:
        return f"ev:a:{event.campaign_id}:{day}:{AD_METRICS[event.name]}"
    return None


def _parse_key(key: str) -> tuple[str, UUID, date, str] | None:
    parts = key.split(":")
    if len(parts) != 5 or parts[0] != "ev" or parts[1] not in {"p", "a"}:
        return None
    try:
        kind = parts[1]
        entity_id = UUID(parts[2])
        day = date.fromisoformat(parts[3])
        metric = parts[4]
    except ValueError:
        return None
    allowed = POST_COLS if kind == "p" else AD_COLS
    if metric not in allowed:
        return None
    return kind, entity_id, day, metric


async def record(redis: Any, events: list[EventIn], *, now: datetime | None = None) -> int:
    clock = now or datetime.now(UTC)
    accepted = 0
    for event in events:
        key = counter_key(event, now=clock)
        if key is None:
            continue
        count = int(await redis.incr(key))
        if count == 1:
            await redis.expire(key, TTL_S)
        await redis.sadd(DIRTY, key)
        accepted += 1
    return accepted


async def rollup(session: AsyncSession, redis: Any) -> int:
    """Move Redis counters into daily rows. Postgres commit happens before Redis is decremented."""
    if int(await redis.incr(LOCK)) != 1:
        return 0
    await redis.expire(LOCK, 110)
    moved = 0
    try:
        for key in list(await redis.smembers(DIRTY)):
            parsed = _parse_key(key)
            raw = await redis.get(key)
            n = int(raw or 0)
            if parsed is None or n <= 0:
                await redis.delete(key)
                await redis.srem(DIRTY, key)
                continue
            kind, entity_id, day, metric = parsed
            try:
                async with session.begin_nested():
                    if kind == "p":
                        await posts_repo.add_daily_stats(session, entity_id, day, **{metric: n})
                    else:
                        await ads_repo.add_daily_stats(session, entity_id, day, **{metric: n})
                await session.commit()
            except IntegrityError:
                await redis.delete(key)
                await redis.srem(DIRTY, key)
                continue
            remaining = int(await redis.decrby(key, n))
            if remaining <= 0:
                await redis.delete(key)
                await redis.srem(DIRTY, key)
            moved += 1
        return moved
    finally:
        await redis.delete(LOCK)
