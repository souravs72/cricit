"""Schemas for dynamic application settings."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


def mask_secret(secret: str | None) -> str:
    """Return a masked representation of a secret key."""
    if not secret:
        return ""
    if len(secret) <= 8:
        return "*" * len(secret)
    return f"{secret[:4]}...{secret[-4:]}"


class AppSettingsRead(BaseModel):
    llm_provider: str
    llm_api_key_set: bool
    llm_api_key_masked: str
    llm_model: str
    youtube_api_key_set: bool
    youtube_api_key_masked: str
    auto_ingest_enabled: bool
    ingest_interval_min: int
    auto_publish_trusted: bool
    extra_config: dict[str, Any] = Field(default_factory=dict)
    updated_at: datetime | None = None


class AppSettingsUpdate(BaseModel):
    llm_provider: str | None = None
    llm_api_key: str | None = None
    llm_model: str | None = None
    youtube_api_key: str | None = None
    auto_ingest_enabled: bool | None = None
    ingest_interval_min: int | None = None
    auto_publish_trusted: bool | None = None
    extra_config: dict[str, Any] | None = None


class TestLlmRequest(BaseModel):
    llm_provider: str
    llm_api_key: str | None = None
    llm_model: str | None = None


class TestLlmResponse(BaseModel):
    ok: bool
    provider: str
    model: str
    latency_ms: int
    sample_output: dict[str, Any] | None = None
    error: str | None = None
