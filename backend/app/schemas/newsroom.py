from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.feed import FeedPage


class SourceOut(BaseModel):
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


class PostListItem(BaseModel):
    id: UUID
    kind: str
    status: str
    category: str
    headline: str
    author_credit: str | None
    published_at: datetime | None
    prompt_version: str | None = None
    tags: list[str] = Field(default_factory=list)


class AdOut(BaseModel):
    id: UUID
    advertiser: str
    format: str
    title: str | None
    is_active: bool
    start_at: datetime
    end_at: datetime
    daily_cap: int | None


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
