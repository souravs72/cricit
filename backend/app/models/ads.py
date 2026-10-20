"""Direct-sold ads and AI cost tracking."""

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, IdMixin, TimestampMixin


class AdCampaign(IdMixin, TimestampMixin, Base):
    __tablename__ = "ad_campaigns"

    advertiser: Mapped[str] = mapped_column(String(120))
    format: Mapped[str] = mapped_column(String(20))  # full_page | footer | sponsored_card
    creative_url: Mapped[str] = mapped_column(String(500))
    click_url: Mapped[str] = mapped_column(String(1000))
    title: Mapped[str | None] = mapped_column(String(160))
    body: Mapped[str | None] = mapped_column(Text)
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    frequency: Mapped[int] = mapped_column(Integer, default=6)  # every N cards
    daily_cap: Mapped[int | None] = mapped_column(Integer)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class AdStatsDaily(Base):
    __tablename__ = "ad_stats_daily"

    campaign_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("ad_campaigns.id", ondelete="CASCADE"), primary_key=True
    )
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    impressions: Mapped[int] = mapped_column(Integer, default=0)
    clicks: Mapped[int] = mapped_column(Integer, default=0)


class AiJob(IdMixin, TimestampMixin, Base):
    __tablename__ = "ai_jobs"

    post_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("posts.id", ondelete="SET NULL"))
    model: Mapped[str] = mapped_column(String(80))
    prompt_version: Mapped[str] = mapped_column(String(40))
    input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    output_tokens: Mapped[int] = mapped_column(Integer, default=0)
    cost_inr: Mapped[float] = mapped_column(Numeric(10, 4), default=0)
    status: Mapped[str] = mapped_column(String(12))  # ok | invalid | error
    error: Mapped[str | None] = mapped_column(Text)
