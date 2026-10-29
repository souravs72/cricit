"""Sources, posts and grassroots submissions."""

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import (
    ARRAY,
    Boolean,
    Computed,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB, TSVECTOR, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, IdMixin, TimestampMixin


class Source(IdMixin, TimestampMixin, Base):
    """An admin-editable "trigger": a news site or a video channel."""

    __tablename__ = "sources"

    name: Mapped[str] = mapped_column(String(120))
    type: Mapped[str] = mapped_column(String(30))  # news | youtube_channel | youtube_search | x
    adapter: Mapped[str | None] = mapped_column(String(20))  # rss | sitemap | html (news only)
    adapter_config: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    default_category: Mapped[str] = mapped_column(String(20), default="international")
    trust_level: Mapped[str] = mapped_column(String(10), default="review")  # auto | review
    priority: Mapped[int] = mapped_column(Integer, default=5)
    fetch_interval_min: Mapped[int] = mapped_column(Integer, default=10)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    consecutive_failures: Mapped[int] = mapped_column(Integer, default=0)
    last_fetched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_error: Mapped[str | None] = mapped_column(Text)
    logo_url: Mapped[str | None] = mapped_column(String(500))


class Post(IdMixin, TimestampMixin, Base):
    """One table for every card kind (read, video, nxtspot) keeps the feed query simple."""

    __tablename__ = "posts"
    __table_args__ = (
        Index("ix_posts_feed", "status", "category", "published_at"),
        Index("ix_posts_search", "search_vector", postgresql_using="gin"),
        Index("ix_posts_tags", "tags", postgresql_using="gin"),
    )

    kind: Mapped[str] = mapped_column(String(10))  # read | video | nxtspot
    status: Mapped[str] = mapped_column(String(10), default="draft", index=True)
    category: Mapped[str] = mapped_column(String(20))  # domestic | international | grassroots
    headline: Mapped[str] = mapped_column(String(160))
    summary: Mapped[str] = mapped_column(Text, default="")
    headline_hi: Mapped[str | None] = mapped_column(String(200))
    summary_hi: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(500))
    original_url: Mapped[str | None] = mapped_column(String(1000))
    url_hash: Mapped[str | None] = mapped_column(String(64), unique=True)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id", ondelete="SET NULL")
    )
    possible_duplicate_of: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("posts.id", ondelete="SET NULL")
    )
    video_id: Mapped[str | None] = mapped_column(String(20))
    author_credit: Mapped[str | None] = mapped_column(String(200))
    tags: Mapped[list[str]] = mapped_column(ARRAY(String(60)), default=list)
    trending_score: Mapped[float] = mapped_column(Float, default=0.0)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False)
    prompt_version: Mapped[str | None] = mapped_column(String(40))
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    search_vector: Mapped[Any] = mapped_column(
        TSVECTOR,
        Computed(
            "setweight(to_tsvector('simple', coalesce(headline, '')), 'A') || "
            "setweight(to_tsvector('simple', coalesce(summary, '')), 'B')",
            persisted=True,
        ),
    )


class PostSource(IdMixin, Base):
    """Extra sources merged into a post by dedupe."""

    __tablename__ = "post_sources"
    __table_args__ = (UniqueConstraint("post_id", "url"),)

    post_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"))
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("sources.id", ondelete="SET NULL")
    )
    url: Mapped[str] = mapped_column(String(1000))


class NxtspotSubmission(IdMixin, TimestampMixin, Base):
    __tablename__ = "nxtspot_submissions"

    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    submitter_name: Mapped[str] = mapped_column(String(120))
    location: Mapped[str | None] = mapped_column(String(160))
    raw_text: Mapped[str] = mapped_column(Text)
    media_urls: Mapped[list[str]] = mapped_column(ARRAY(String(500)), default=list)
    # new | drafted | published | rejected
    status: Mapped[str] = mapped_column(String(12), default="new")
    post_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("posts.id", ondelete="SET NULL"))


class PostStatsDaily(Base):
    """Rolled up hourly from Redis counters. No raw event rows are ever stored."""

    __tablename__ = "post_stats_daily"

    post_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("posts.id", ondelete="CASCADE"), primary_key=True
    )
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    views: Mapped[int] = mapped_column(Integer, default=0)
    opens: Mapped[int] = mapped_column(Integer, default=0)
    shares: Mapped[int] = mapped_column(Integer, default=0)
    bookmarks: Mapped[int] = mapped_column(Integer, default=0)
