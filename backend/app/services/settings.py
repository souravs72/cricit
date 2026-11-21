"""Business logic for application settings and provider testing."""

from __future__ import annotations

import time
import uuid
from typing import Any

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.client import (
    SUMMARY_SCHEMA,
    AnthropicClient,
    GeminiClient,
    LLMClient,
    LocalDeterministicLLMClient,
    OpenAIClient,
)
from app.core.config import get_settings as get_env_settings
from app.repositories import settings as settings_repo
from app.schemas.settings import (
    AppSettingsRead,
    AppSettingsUpdate,
    TestLlmRequest,
    TestLlmResponse,
    mask_secret,
)

log = structlog.get_logger()


def build_client_for_test(
    provider: str,
    api_key: str,
    model: str | None = None,
) -> LLMClient:
    """Build a specific LLM client for testing."""
    p = (provider or "").strip().lower()
    if p == "gemini":
        return GeminiClient(api_key=api_key, model=model or "gemini-1.5-flash")
    if p in ("openai", "openrouter"):
        return OpenAIClient(api_key=api_key, model=model or "gpt-4o-mini")
    if p == "anthropic":
        return AnthropicClient(api_key=api_key, model=model or "claude-3-5-haiku-20241022")
    if p == "local":
        return LocalDeterministicLLMClient()
    raise ValueError(f"Unsupported LLM provider: {provider}")


async def get_owner_settings(session: AsyncSession) -> AppSettingsRead:
    """Fetch current app settings, masking sensitive keys."""
    row = await settings_repo.get_settings(session)
    env = get_env_settings()

    effective_llm_key = row.llm_api_key or env.llm_api_key or ""
    effective_yt_key = row.youtube_api_key or env.youtube_api_key or ""

    return AppSettingsRead(
        llm_provider=row.llm_provider or env.llm_provider or "anthropic",
        llm_api_key_set=bool(effective_llm_key),
        llm_api_key_masked=mask_secret(effective_llm_key),
        llm_model=row.llm_model or env.llm_model or "claude-3-5-haiku-20241022",
        youtube_api_key_set=bool(effective_yt_key),
        youtube_api_key_masked=mask_secret(effective_yt_key),
        auto_ingest_enabled=row.auto_ingest_enabled,
        ingest_interval_min=row.ingest_interval_min,
        auto_publish_trusted=row.auto_publish_trusted,
        extra_config=row.extra_config or {},
        updated_at=row.updated_at,
    )


async def update_owner_settings(
    session: AsyncSession,
    data: AppSettingsUpdate,
    admin_id: uuid.UUID | None = None,
) -> AppSettingsRead:
    """Update settings in database."""
    updates = data.model_dump(exclude_unset=True)

    # Don't overwrite key with empty string if the client sent an empty or whitespace string without intent
    # Unless explicitly set to empty to clear it.
    if "llm_api_key" in updates and updates["llm_api_key"] is not None:
        updates["llm_api_key"] = updates["llm_api_key"].strip()
    if "youtube_api_key" in updates and updates["youtube_api_key"] is not None:
        updates["youtube_api_key"] = updates["youtube_api_key"].strip()

    await settings_repo.update_settings(session, updates=updates, updated_by=admin_id)
    return await get_owner_settings(session)


async def test_llm_connection(
    session: AsyncSession,
    req: TestLlmRequest,
) -> TestLlmResponse:
    """Test LLM connectivity and JSON schema extraction."""
    start_time = time.monotonic()
    provider = req.llm_provider.lower().strip()
    model = (req.llm_model or "").strip()

    # Determine API key: passed directly or read from DB/env
    api_key = (req.llm_api_key or "").strip()
    if not api_key and provider != "local":
        db_settings = await settings_repo.get_settings(session)
        api_key = db_settings.llm_api_key or get_env_settings().llm_api_key or ""

    if not api_key and provider != "local":
        return TestLlmResponse(
            ok=False,
            provider=provider,
            model=model or "default",
            latency_ms=0,
            error="API key is required to test this provider.",
        )

    try:
        client = build_client_for_test(provider, api_key, model)
        test_article = (
            "Rohit Sharma notched a commanding century as India asserted dominance in the Test match. "
            "The captain struck 14 boundaries and two sixes, reaching three figures in 157 deliveries "
            "under tough morning batting conditions against a disciplined bowling attack."
        )
        res = await client.complete_json(
            system="You are a professional cricket journalist and news editor for CRICIT.",
            user=f"Summarize this news article strictly in JSON format:\n\n{test_article}",
            schema=SUMMARY_SCHEMA,
            max_tokens=400,
        )
        latency = int((time.monotonic() - start_time) * 1000)
        return TestLlmResponse(
            ok=True,
            provider=provider,
            model=res.model,
            latency_ms=latency,
            sample_output=res.data,
        )
    except Exception as exc:
        latency = int((time.monotonic() - start_time) * 1000)
        log.error("test_llm_connection_failed", provider=provider, error=str(exc))
        return TestLlmResponse(
            ok=False,
            provider=provider,
            model=model or "unknown",
            latency_ms=latency,
            error=str(exc)[:500],
        )
