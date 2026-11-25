"""Database repository for AppSettings."""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.settings import AppSettings


async def get_settings(session: AsyncSession) -> AppSettings:
    """Fetch the singleton AppSettings row (id=1), creating it if missing."""
    settings = await session.get(AppSettings, 1)
    if settings is None:
        settings = AppSettings(
            id=1,
            llm_provider="anthropic",
            llm_api_key="",
            llm_model="claude-3-5-haiku-20241022",
            youtube_api_key="",
            auto_ingest_enabled=True,
            ingest_interval_min=15,
            auto_publish_trusted=True,
            extra_config={},
        )
        session.add(settings)
        await session.flush()
    return settings


async def update_settings(
    session: AsyncSession,
    *,
    updates: dict[str, Any],
    updated_by: uuid.UUID | None = None,
) -> AppSettings:
    """Update settings fields and persist."""
    settings = await get_settings(session)
    for field, value in updates.items():
        if value is not None and hasattr(settings, field):
            setattr(settings, field, value)
    if updated_by is not None:
        settings.updated_by = updated_by
    await session.commit()
    await session.refresh(settings)
    return settings
