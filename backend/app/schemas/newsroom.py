from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.feed import FeedPage


class SourceOut(BaseModel):
    """GET /admin/v1/sources. User: "Check what is tobe built now into this - build it" """

    id: UUID
    name: str
    type: str
    adapter: str | None
    default_category: str
    trust_level: str
    is_active: bool
    consecutive_failures: int
    last_error: str | None
    last_fetched_at: datetime | None
    feed_url: str | None = None
    fetch_interval_min: int = 10


class PostListItem(BaseModel):
    """GET /admin/v1/posts and /review; POST publish/reject response."""

    id: UUID
    kind: str
    status: str
    category: str
    headline: str
    summary: str = ""
    headline_hi: str | None = None
    summary_hi: str | None = None
    image_url: str | None = None
    author_credit: str | None
    published_at: datetime | None
    prompt_version: str | None = None
    tags: list[str] = Field(default_factory=list)
    original_url: str | None = None
    possible_duplicate_of: UUID | None = None
    duplicate_headline: str | None = None


class PostUpdateIn(BaseModel):
    headline: str | None = None
    summary: str | None = None
    headline_hi: str | None = None
    summary_hi: str | None = None
    category: str | None = None
    tags: list[str] | None = None
    image_url: str | None = None
    author_credit: str | None = None
    status: Literal["draft", "review", "published", "rejected"] | None = None
    publish_now: bool = False


class PostCreateIn(BaseModel):
    headline: str
    summary: str
    headline_hi: str | None = None
    summary_hi: str | None = None
    category: str = "international"
    kind: str = "read"
    tags: list[str] = Field(default_factory=list)
    image_url: str | None = None
    author_credit: str | None = "CRICIT Newsroom"
    original_url: str | None = None
    status: Literal["draft", "review", "published"] = "published"


class CurateIn(BaseModel):
    raw_text: str | None = None
    url: str | None = None
    category: str | None = None
    notes: str | None = None


class CurateOut(BaseModel):
    headline: str
    summary: str
    headline_hi: str | None = None
    summary_hi: str | None = None
    category: str
    tags: list[str] = Field(default_factory=list)
    image_url: str | None = None
    author_credit: str = "CRICIT Newsroom"


class AdOut(BaseModel):
    id: UUID
    advertiser: str
    format: str
    title: str | None
    is_active: bool
    start_at: datetime
    end_at: datetime
    daily_cap: int | None
    impressions_today: int = 0
    clicks_today: int = 0


class AuditOut(BaseModel):
    id: UUID
    action: str
    entity: str
    entity_id: str | None
    ts: datetime
    note: str | None


class OverviewStats(BaseModel):
    cards_published_today: int
    waiting_for_review: int
    readers_today: int
    ai_cost_today: str
    review: list[PostListItem]
    sources: list[SourceOut]


class SearchQuery(BaseModel):
    q: str = Field(min_length=1, max_length=80)


class DiscoverOut(BaseModel):
    trending: list[str]
    nxtspot: FeedPage


class NxtspotOut(BaseModel):
    id: UUID
    submitter_name: str
    location: str | None
    status: str
    raw_text: str
