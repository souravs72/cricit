"""ARQ worker. Run with: arq app.workers.main.WorkerSettings

Every job must be idempotent: safe to run twice with the same input.
"""

from datetime import UTC, datetime
from typing import Any, ClassVar
from uuid import UUID

from arq import cron
from arq.connections import RedisSettings

from app.core.config import get_settings
from app.core.db import get_sessionmaker
from app.core.logging import configure_logging
from app.repositories import sources as sources_repo
from app.services.ingest import fetch_and_store, is_due, job_id_for


async def fetch_source(ctx: dict[str, Any], source_id: str) -> dict[str, Any]:
    """Fetch one RSS source. Job id is source+interval slot so retries collapse."""
    del ctx
    async with get_sessionmaker()() as db:
        result = await fetch_and_store(db, UUID(source_id))
    return {str(k): v for k, v in result.items()}


async def fetch_due_sources(ctx: dict[str, Any]) -> None:
    """Enqueue one fetch_source job per due RSS source (id = source+interval slot)."""
    now = datetime.now(UTC)
    async with get_sessionmaker()() as db:
        sources = await sources_repo.list_active_rss(db)
    redis = ctx.get("redis")
    for source in sources:
        if not is_due(source, now=now):
            continue
        job_id = job_id_for(source.id, source.fetch_interval_min, at=now)
        if redis is None:
            await fetch_source(ctx, str(source.id))
            continue
        await redis.enqueue_job("fetch_source", str(source.id), _job_id=job_id)


async def fetch_youtube(ctx: dict[str, Any]) -> None:
    """T17: read uploads playlists of video sources, keep Shorts."""


async def rollup_stats(ctx: dict[str, Any]) -> None:
    """T26: move Redis counters into post_stats_daily / ad_stats_daily."""


async def nightly_housekeeping(ctx: dict[str, Any]) -> None:
    """Archive old posts, purge expired ads, purge soft-deleted users past 30 days."""


async def startup(ctx: dict[str, Any]) -> None:
    configure_logging(get_settings().log_level)


class WorkerSettings:
    functions: ClassVar[list[Any]] = [fetch_due_sources, fetch_source, fetch_youtube, rollup_stats]
    cron_jobs: ClassVar[list[Any]] = [
        cron(fetch_due_sources, minute=set(range(0, 60, 2)), run_at_startup=False),
        cron(fetch_youtube, minute={5, 20, 35, 50}),
        cron(rollup_stats, minute={0}),
        cron(nightly_housekeeping, hour={21}, minute={30}),  # 03:00 IST
    ]
    on_startup = startup
    redis_settings = RedisSettings.from_dsn(get_settings().redis_url)
    max_tries = 3
    job_timeout = 120
