"""App Settings model for runtime owner configuration."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class AppSettings(Base, TimestampMixin):
    """Runtime system settings configurable by the app owner. Singleton row (id=1)."""

    __tablename__ = "app_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)

    # LLM & AI Engine Configuration
    llm_provider: Mapped[str] = mapped_column(String(32), default="anthropic", nullable=False)
    llm_api_key: Mapped[str] = mapped_column(Text, default="", nullable=False)
    llm_model: Mapped[str] = mapped_column(String(64), default="claude-3-5-haiku-20241022", nullable=False)

    # External APIs
    youtube_api_key: Mapped[str] = mapped_column(Text, default="", nullable=False)

    # Ingestion Engine Automation
    auto_ingest_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    ingest_interval_min: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    auto_publish_trusted: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Additional custom parameters
    extra_config: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)

    updated_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
