"""Production-grade Continuous News Ingestion & Intelligence Engine.

Manages scheduled polling, concurrency throttling, fault-isolated multi-source
fetching, conditional HTTP caching, deduplication, and asynchronous AI enrichment.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

import structlog
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models import Source
from app.repositories import settings as settings_repo
from app.repositories import sources as sources_repo
from app.services.ingest import fetch_and_store, is_due

log = structlog.get_logger()


class ContinuousIngestionEngine:
    """Orchestrates continuous background ingestion across all configured sources."""

    def __init__(self, max_concurrency: int = 10) -> None:
        self.max_concurrency = max_concurrency
        self.semaphore = asyncio.Semaphore(max_concurrency)
        self.is_running = False
        self._task: asyncio.Task[None] | None = None
        self.last_run_at: datetime | None = None
        self.total_runs = 0
        self.total_created = 0
        self.total_merged = 0
        self.total_failures = 0
        self.last_error: str | None = None

    async def ingest_source(
        self,
        db: AsyncSession,
        source_id: UUID,
        *,
        enrich_with_ai: bool = True,
    ) -> dict[str, Any]:
        """Fetch and process a single source inside a concurrency semaphore."""
        async with self.semaphore:
            try:
                res = await fetch_and_store(db, source_id)
                created = int(res.get("created", 0))
                merged = int(res.get("merged", 0))
                self.total_created += created
                self.total_merged += merged
                return res
            except Exception as exc:
                self.total_failures += 1
                self.last_error = str(exc)[:400]
                log.error("ingest_source_error", source_id=str(source_id), error=str(exc))
                return {"failed": True, "error": str(exc), "created": 0, "merged": 0}

    async def run_once(
        self,
        sessionmaker: async_sessionmaker[AsyncSession],
        *,
        force_all: bool = False,
        enrich_with_ai: bool = True,
    ) -> dict[str, Any]:
        """Poll all active sources, checking for due intervals, and ingest concurrently."""
        now = datetime.now(UTC)
        self.last_run_at = now
        self.total_runs += 1

        async with sessionmaker() as db:
            settings_row = await settings_repo.get_settings(db)
            if not force_all and not settings_row.auto_ingest_enabled:
                return {
                    "timestamp": now.isoformat(),
                    "due_sources_count": 0,
                    "created": 0,
                    "merged": 0,
                    "status": "disabled",
                }
            sources = await sources_repo.list_active_fetchable(db)

        due_sources = [s for s in sources if force_all or is_due(s, now=now)]
        if not due_sources:
            return {
                "timestamp": now.isoformat(),
                "due_sources_count": 0,
                "created": 0,
                "merged": 0,
                "status": "idle",
            }

        log.info("ingest_run_started", due_count=len(due_sources))

        async def _worker(source: Source) -> dict[str, Any]:
            async with sessionmaker() as session:
                return await self.ingest_source(
                    session,
                    source.id,
                    enrich_with_ai=enrich_with_ai,
                )

        # Fault isolation: return_exceptions=True ensures one failure never stops others
        results = await asyncio.gather(*[_worker(s) for s in due_sources], return_exceptions=True)

        created_sum = 0
        merged_sum = 0
        failures = 0
        for r in results:
            if isinstance(r, dict):
                created_sum += int(r.get("created", 0))
                merged_sum += int(r.get("merged", 0))
                if r.get("failed"):
                    failures += 1
            else:
                failures += 1

        log.info(
            "ingest_run_completed",
            due_count=len(due_sources),
            created=created_sum,
            merged=merged_sum,
            failures=failures,
        )

        return {
            "timestamp": now.isoformat(),
            "due_sources_count": len(due_sources),
            "created": created_sum,
            "merged": merged_sum,
            "failures": failures,
            "status": "completed",
        }

    async def start_loop(
        self,
        sessionmaker: async_sessionmaker[AsyncSession],
        poll_interval_s: int = 60,
    ) -> None:
        """Continuous background loop for non-blocking autonomous ingestion."""
        self.is_running = True
        log.info("continuous_ingest_loop_started", interval_s=poll_interval_s)
        try:
            while self.is_running:
                try:
                    await self.run_once(sessionmaker)
                except Exception as exc:
                    log.error("continuous_ingest_iteration_error", error=str(exc))
                await asyncio.sleep(poll_interval_s)
        except asyncio.CancelledError:
            self.is_running = False
            log.info("continuous_ingest_loop_cancelled")

    def stop(self) -> None:
        self.is_running = False
        if self._task and not self._task.done():
            self._task.cancel()

    def get_status(self) -> dict[str, Any]:
        return {
            "is_running": self.is_running,
            "last_run_at": self.last_run_at.isoformat() if self.last_run_at else None,
            "total_runs": self.total_runs,
            "total_created": self.total_created,
            "total_merged": self.total_merged,
            "total_failures": self.total_failures,
            "max_concurrency": self.max_concurrency,
            "last_error": self.last_error,
        }


# Singleton instance
engine = ContinuousIngestionEngine(max_concurrency=10)
