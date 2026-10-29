"""Read models for the newsroom dashboard and public search."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.models import Post, Source
from app.repositories import ads as ads_repo
from app.repositories import audit as audit_repo
from app.repositories import nxtspot as nxtspot_repo
from app.repositories import posts as posts_repo
from app.repositories import sources as sources_repo
from app.schemas.feed import FeedPage, Lang
from app.schemas.newsroom import (
    AdOut,
    AuditOut,
    DiscoverOut,
    NxtspotOut,
    OverviewStats,
    PostListItem,
    SourceOut,
)
from app.services.feed import to_card


def source_out(row: Source) -> SourceOut:
    """Map a Source ORM row to SourceOut. Callers: list_sources, services.sources."""
    cfg = row.adapter_config or {}
    feed = cfg.get("feed_url") or cfg.get("listing_url") or cfg.get("sitemap_url")
    return SourceOut(
        id=row.id,
        name=row.name,
        type=row.type,
        adapter=row.adapter,
        default_category=row.default_category,
        trust_level=row.trust_level,
        is_active=row.is_active,
        consecutive_failures=row.consecutive_failures,
        last_error=row.last_error,
        last_fetched_at=row.last_fetched_at,
        feed_url=feed if isinstance(feed, str) else None,
        fetch_interval_min=row.fetch_interval_min,
    )


def post_item(row: Post) -> PostListItem:
    """Map a Post ORM row. Callers: list_posts, list_review, services.posts."""
    return PostListItem.model_validate(row, from_attributes=True)


async def list_sources(db: AsyncSession) -> list[SourceOut]:
    return [source_out(s) for s in await sources_repo.list_all(db)]


async def list_posts(
    db: AsyncSession, *, status: str | None = None, category: str | None = None
) -> list[PostListItem]:
    return [post_item(p) for p in await posts_repo.list_all(db, status=status, category=category)]


async def list_review(db: AsyncSession) -> list[PostListItem]:
    return [post_item(p) for p in await posts_repo.list_by_status(db, status="review")]


async def list_ads(db: AsyncSession) -> list[AdOut]:
    return [AdOut.model_validate(a, from_attributes=True) for a in await ads_repo.list_all(db)]


async def list_audit(db: AsyncSession) -> list[AuditOut]:
    return [
        AuditOut.model_validate(a, from_attributes=True) for a in await audit_repo.list_recent(db)
    ]


async def overview(db: AsyncSession) -> OverviewStats:
    today = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    published = await posts_repo.count_published_since(db, today)
    waiting = await posts_repo.count_status(db, "review")
    return OverviewStats(
        cards_published_today=published,
        waiting_for_review=waiting,
        readers_today=0,
        ai_cost_today="₹0",
        review=await list_review(db),
        sources=await list_sources(db),
    )


async def list_nxtspot(db: AsyncSession) -> list[NxtspotOut]:
    return [
        NxtspotOut.model_validate(row, from_attributes=True)
        for row in await nxtspot_repo.list_recent(db)
    ]


async def search(db: AsyncSession, settings: Settings, *, q: str, lang: Lang) -> FeedPage:
    rows = await posts_repo.search_published(db, q, limit=settings.feed_page_size)
    share_base = settings.cdn_base_url or "https://cricit.app"
    return FeedPage(items=[to_card(p, lang, share_base) for p in rows], next_cursor=None)


async def discover(db: AsyncSession, settings: Settings, *, lang: Lang) -> DiscoverOut:
    share_base = settings.cdn_base_url or "https://cricit.app"
    grassroots = await posts_repo.list_published(
        db, category="grassroots", kind=None, after=None, limit=8
    )
    recent = await posts_repo.list_published(db, category=None, kind=None, after=None, limit=20)
    tags: list[str] = []
    for post in recent:
        for tag in post.tags or []:
            if tag not in tags:
                tags.append(tag)
    items = [to_card(p, lang, share_base) for p in grassroots]
    return DiscoverOut(trending=tags[:8], nxtspot=FeedPage(items=items, next_cursor=None))
