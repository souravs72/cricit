"""Tests for dynamic owner AppSettings and Admin Settings API."""

from __future__ import annotations

from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.core.db import get_session
from app.main import create_app
from app.models.settings import AppSettings
from app.schemas.settings import mask_secret


@pytest.fixture
def test_app():
    app = create_app()
    mock_session = AsyncMock()
    app.dependency_overrides[get_session] = lambda: mock_session
    return app


def test_mask_secret():
    assert mask_secret("") == ""
    assert mask_secret("12345") == "*****"
    assert mask_secret("sk-ant-api03-abcdefghijklmnop") == "sk-a...mnop"


def test_get_settings_permissions(test_app, token_for):
    client = TestClient(test_app)

    # Anonymous denied
    resp = client.get("/admin/v1/settings")
    assert resp.status_code in (401, 403)

    # Viewer denied (settings:manage only for owner)
    resp = client.get("/admin/v1/settings", headers={"Authorization": f"Bearer {token_for('viewer')}"})
    assert resp.status_code == 403

    # Editor denied
    resp = client.get("/admin/v1/settings", headers={"Authorization": f"Bearer {token_for('editor')}"})
    assert resp.status_code == 403

    # Owner allowed
    with patch("app.services.settings.get_owner_settings", new_callable=AsyncMock) as mock_get:
        from app.schemas.settings import AppSettingsRead
        mock_get.return_value = AppSettingsRead(
            llm_provider="anthropic",
            llm_api_key_set=True,
            llm_api_key_masked="sk-a...mnop",
            llm_model="claude-3-5-haiku-20241022",
            youtube_api_key_set=False,
            youtube_api_key_masked="",
            auto_ingest_enabled=True,
            ingest_interval_min=15,
            auto_publish_trusted=True,
            extra_config={},
        )
        resp = client.get("/admin/v1/settings", headers={"Authorization": f"Bearer {token_for('owner')}"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["llm_provider"] == "anthropic"
        assert data["llm_api_key_set"] is True
        assert data["llm_api_key_masked"] == "sk-a...mnop"


def test_patch_settings_owner(test_app, token_for):
    client = TestClient(test_app)

    with patch("app.services.settings.update_owner_settings", new_callable=AsyncMock) as mock_update, \
         patch("app.repositories.audit.write", new_callable=AsyncMock) as mock_audit:
        from app.schemas.settings import AppSettingsRead
        mock_update.return_value = AppSettingsRead(
            llm_provider="openai",
            llm_api_key_set=True,
            llm_api_key_masked="sk-p...9999",
            llm_model="gpt-4o-mini",
            youtube_api_key_set=True,
            youtube_api_key_masked="AIza...1234",
            auto_ingest_enabled=False,
            ingest_interval_min=30,
            auto_publish_trusted=False,
            extra_config={},
        )

        resp = client.patch(
            "/admin/v1/settings",
            json={
                "llm_provider": "openai",
                "llm_api_key": "sk-proj-test-key-123456789999",
                "llm_model": "gpt-4o-mini",
                "youtube_api_key": "AIzaSyTestKey1234",
                "auto_ingest_enabled": False,
                "ingest_interval_min": 30,
            },
            headers={"Authorization": f"Bearer {token_for('owner')}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["llm_provider"] == "openai"
        assert data["auto_ingest_enabled"] is False
        mock_update.assert_awaited_once()
        mock_audit.assert_awaited_once()


def test_test_llm_connection_endpoint(test_app, token_for):
    client = TestClient(test_app)

    # Test with local provider
    resp = client.post(
        "/admin/v1/settings/test-llm",
        json={"llm_provider": "local", "llm_model": "local-deterministic-v1"},
        headers={"Authorization": f"Bearer {token_for('owner')}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["ok"] is True
    assert data["provider"] == "local"
    assert "headline" in data["sample_output"]
