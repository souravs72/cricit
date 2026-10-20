"""ARQ worker. Run with: arq app.workers.main.WorkerSettings

Every job must be idempotent: safe to run twice with the same input.
"""

from typing import Any, ClassVar

from arq import cron
from arq.connections import RedisSettings

from app.core.config import get_settings
from app.core.logging import configure_logging


async def fetch_due_sources(ctx: dict[str, Any]) -> None:
    """T10: enqueue one fetch_source job per active source whose interval has elapsed."""


async def fetch_youtube(ctx: dict[str, Any]) -> None:
    """T17: read uploads playlists of video sources, keep Shorts."""


async def rollup_stats(ctx: dict[str, Any]) -> None:
    """T26: move Redis counters into post_stats_daily / ad_stats_daily."""


async def nightly_housekeeping(ctx: dict[str, Any]) -> None:
    """Archive old posts, purge expired ads, purge soft-deleted users past 30 days."""


async def startup(ctx: dict[str, Any]) -> None:
    configure_logging(get_settings().log_level)


class WorkerSettings:
    functions: ClassVar[list[Any]] = [fetch_due_sources, fetch_youtube, rollup_stats]
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
