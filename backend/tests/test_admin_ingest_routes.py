"""API integration tests for Admin Ingestion Endpoints.

Tests:
1. POST /admin/v1/sources/{source_id}/ingest (permission check + execution)
2. POST /admin/v1/ingest/run (batch cycle trigger)
3. GET /admin/v1/ingest/status (engine health & counters)
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.core.db import get_session
from app.main import create_app


@pytest.fixture
def test_app():
    app = create_app()
    mock_session = AsyncMock()
    app.dependency_overrides[get_session] = lambda: mock_session
    return app


def test_ingest_status_endpoint(test_app, token_for) -> None:
    client = TestClient(test_app)
    headers = {"Authorization": f"Bearer {token_for('viewer')}"}

    with patch("app.services.continuous_ingest.engine.get_status") as mock_status:
        mock_status.return_value = {
            "is_running": True,
            "max_concurrency": 10,
            "total_runs": 4,
            "total_created": 12,
            "total_merged": 3,
            "total_failures": 0,
            "last_run_at": "2026-11-08T00:00:00Z",
            "last_error": None,
        }

        resp = client.get("/admin/v1/ingest/status", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_running"] is True
        assert data["total_created"] == 12
        assert data["max_concurrency"] == 10


def test_source_ingest_endpoint(test_app, token_for) -> None:
    client = TestClient(test_app)
    headers = {"Authorization": f"Bearer {token_for('editor')}"}
    source_id = uuid4()

    with (
        patch("app.services.ingest.fetch_and_store", new_callable=AsyncMock) as mock_fetch,
        patch("app.repositories.audit.write", new_callable=AsyncMock) as mock_audit,
    ):
        mock_fetch.return_value = {
            "created": 5,
            "merged": 2,
            "items": 7,
        }

        resp = client.post(f"/admin/v1/sources/{source_id}/ingest", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["created"] == 5
        assert data["merged"] == 2
        mock_fetch.assert_awaited_once()
        mock_audit.assert_awaited_once()


def test_ingest_run_batch_endpoint(test_app, token_for) -> None:
    client = TestClient(test_app)
    headers = {"Authorization": f"Bearer {token_for('owner')}"}

    with (
        patch("app.services.continuous_ingest.engine.run_once", new_callable=AsyncMock) as mock_run,
        patch("app.repositories.audit.write", new_callable=AsyncMock),
        patch("app.core.db.get_sessionmaker") as mock_maker,
    ):
        mock_session = AsyncMock()
        mock_maker.return_value.return_value.__aenter__.return_value = mock_session

        mock_run.return_value = {
            "status": "completed",
            "due_sources_count": 4,
            "created": 8,
            "merged": 3,
            "failures": 0,
        }

        resp = client.post("/admin/v1/ingest/run", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "completed"
        assert data["created"] == 8
        assert data["merged"] == 3
        mock_run.assert_awaited_once()


def test_ingest_endpoints_reject_unauthorized(test_app) -> None:
    client = TestClient(test_app)
    r1 = client.get("/admin/v1/ingest/status")
    assert r1.status_code == 401

    r2 = client.post("/admin/v1/ingest/run")
    assert r2.status_code == 401

    r3 = client.post(f"/admin/v1/sources/{uuid4()}/ingest")
    assert r3.status_code == 401
