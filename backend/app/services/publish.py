"""Warm the public feed cache after an editorial publish (T16).

Callers: services.posts.publish, tests/test_feed_cache.py.
API: POST /admin/v1/posts/{id}/publish then GET /v1/feed.
Schema: FeedPage JSON in Redis keys feed:{tab}:{lang}:{cursor}.
User: "try focusing on them and try building it."
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.redis import get_redis
from app.models import Post
from app.schemas.feed import Lang, Tab
from app.services.feed import FeedCache, affected_tabs, build_feed_page

if TYPE_CHECKING:
    from redis.asyncio import Redis

_LANGS: tuple[Lang, ...] = ("en", "hi")


async def invalidate_all_feeds(cache: FeedCache | None = None) -> None:
    store = cache if cache is not None else FeedCache(get_redis())
    tabs: tuple[Tab, ...] = ("feed", "video", "domestic", "international", "nxtspot")
    for tab in tabs:
        for lang in _LANGS:
            await store.drop(tab, lang)


async def rebuild_after_publish(
    session: AsyncSession,
    post: Post,
    *,
    settings: Settings | None = None,
    cache: FeedCache | None = None,
    redis: Redis | None = None,
) -> None:
    cfg = settings or get_settings()
    store = cache if cache is not None else FeedCache(redis if redis is not None else get_redis())
    for tab in affected_tabs(post):
        for lang in _LANGS:
            await store.drop(tab, lang)
            cursor: str | None = None
            for _ in range(cfg.feed_cache_pages):
                page = await build_feed_page(session, cfg, tab=tab, lang=lang, cursor=cursor)
                await store.set(tab, lang, cursor or "", page, ttl_s=cfg.feed_cache_ttl_s)
                cursor = page.next_cursor
                if not cursor:
                    break
