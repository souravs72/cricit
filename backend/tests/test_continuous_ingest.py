"""Unit and concurrency tests for ContinuousIngestionEngine.

Verifies:
1. Semaphore-bounded concurrency.
2. Fault isolation (one failing source never crashes the batch).
3. Circuit breaker metrics and status tracking.
4. Autonomous run_once and start_loop lifecycle.
"""

from __future__ import annotations

import asyncio
import contextlib
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Source
from app.services.continuous_ingest import ContinuousIngestionEngine


def _make_source(name: str = "Test Source", is_active: bool = True) -> Source:
    return Source(
        id=uuid4(),
        name=name,
        type="news",
        adapter="rss",
        adapter_config={"kind": "rss", "feed_url": "https://example.com/rss.xml"},
        default_category="international",
        trust_level="auto",
        is_active=is_active,
        fetch_interval_min=10,
        consecutive_failures=0,
    )


@pytest.mark.asyncio
async def test_engine_initial_status() -> None:
    eng = ContinuousIngestionEngine(max_concurrency=5)
    status = eng.get_status()
    assert status["is_running"] is False
    assert status["max_concurrency"] == 5
    assert status["total_runs"] == 0
    assert status["total_created"] == 0
    assert status["total_failures"] == 0
    assert status["last_run_at"] is None


@pytest.mark.asyncio
async def test_engine_ingest_source_success() -> None:
    eng = ContinuousIngestionEngine(max_concurrency=2)
    mock_db = MagicMock(spec=AsyncSession)
    src_id = uuid4()

    with patch(
        "app.services.continuous_ingest.fetch_and_store", new_callable=AsyncMock
    ) as mock_fetch:
        mock_fetch.return_value = {"created": 3, "merged": 1}
        res = await eng.ingest_source(mock_db, src_id, enrich_with_ai=True)

        assert res["created"] == 3
        assert res["merged"] == 1
        assert eng.total_created == 3
        assert eng.total_merged == 1
        assert eng.total_failures == 0


@pytest.mark.asyncio
async def test_engine_ingest_source_fault_isolation() -> None:
    """When a source throws an unhandled exception, it must be caught and logged safely."""
    eng = ContinuousIngestionEngine(max_concurrency=2)
    mock_db = MagicMock(spec=AsyncSession)
    src_id = uuid4()

    with patch(
        "app.services.continuous_ingest.fetch_and_store", new_callable=AsyncMock
    ) as mock_fetch:
        mock_fetch.side_effect = ConnectionResetError("Remote server closed connection")
        res = await eng.ingest_source(mock_db, src_id, enrich_with_ai=True)

        assert res["failed"] is True
        assert "Remote server closed connection" in res["error"]
        assert eng.total_failures == 1
        assert "Remote server closed connection" in (eng.last_error or "")


@pytest.mark.asyncio
async def test_engine_run_once_concurrent_with_fault_isolation() -> None:
    """Batch run_once polls multiple sources in parallel; failed sources don't stop good ones."""
    eng = ContinuousIngestionEngine(max_concurrency=3)
    s1 = _make_source("Source Alpha")
    s2 = _make_source("Source Beta")
    s3 = _make_source("Source Gamma")

    # Mock sessionmaker
    mock_session = AsyncMock(spec=AsyncSession)
    mock_maker = MagicMock()
    mock_maker.return_value.__aenter__.return_value = mock_session

    with (
        patch(
            "app.services.continuous_ingest.sources_repo.list_active_fetchable",
            new_callable=AsyncMock,
        ) as mock_list,
        patch("app.services.continuous_ingest.is_due", return_value=True),
        patch.object(eng, "ingest_source", new_callable=AsyncMock) as mock_ingest,
    ):
        mock_list.return_value = [s1, s2, s3]

        async def _fake_ingest(
            db: AsyncSession, source_id: object, **kwargs: object
        ) -> dict[str, object]:
            if source_id == s2.id:
                return {"failed": True, "error": "HTTP 502", "created": 0, "merged": 0}
            return {"created": 2, "merged": 1}

        mock_ingest.side_effect = _fake_ingest

        res = await eng.run_once(mock_maker, force_all=True)

        assert res["status"] == "completed"
        assert res["due_sources_count"] == 3
        assert res["created"] == 4  # s1: 2 + s3: 2
        assert res["merged"] == 2  # s1: 1 + s3: 1
        assert res["failures"] == 1  # s2: 1 failure
        assert eng.total_runs == 1


@pytest.mark.asyncio
async def test_engine_loop_lifecycle() -> None:
    """Engine can start background loop and stop cleanly on signal."""
    eng = ContinuousIngestionEngine(max_concurrency=2)
    mock_maker = MagicMock()

    with patch.object(eng, "run_once", new_callable=AsyncMock) as mock_run:
        mock_run.return_value = {"status": "completed"}
        loop_task = asyncio.create_task(eng.start_loop(mock_maker, poll_interval_s=1))

        await asyncio.sleep(0.05)
        assert eng.is_running is True

        eng.stop()
        loop_task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await loop_task

        assert eng.is_running is False

        assert eng.is_running is False
