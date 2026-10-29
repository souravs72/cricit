"""Public feed: cards, ad/Nxtspot interleaving, Redis page cache (T16).

Callers: api/v1/routes.get_feed, newsroom.search/discover, services.publish,
tests/test_feed_integration.py, tests/test_feed_cache.py.
API: GET /v1/feed, GET /v1/config. Schema: FeedPage (Card | AdSlot).
User: "try focusing on them and try building it."
"""

from __future__ import annotations

import contextlib
from collections.abc import Set as AbstractSet
from datetime import UTC, datetime
from typing import Any, Literal, cast

from pydantic import HttpUrl, TypeAdapter, ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.models import AdCampaign, Post
from app.repositories import ads as ads_repo
from app.repositories import posts as posts_repo
from app.schemas.feed import (
    AdSlot,
    Card,
    CardSource,
    FeedPage,
    Lang,
    Tab,
    decode_cursor,
    encode_cursor,
)

FEED_CACHE_CONTROL = "public, s-maxage=60, stale-while-revalidate=300"

_TAB: dict[Tab, tuple[str | None, str | None]] = {
    "feed": (None, None),
    "video": (None, "video"),
    "domestic": ("domestic", None),
    "international": ("international", None),
    "nxtspot": ("grassroots", None),
}

_IN_FEED_AD = frozenset({"sponsored_card", "full_page"})
_HTTP = TypeAdapter(HttpUrl)


def _http(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return str(_HTTP.validate_python(value))
    except (ValidationError, ValueError, TypeError):
        return None


class FakeRedis:
    """In-memory stand-in used by tests. Same async get/set/delete/sadd/smembers as Redis."""

    def __init__(self) -> None:
        self.kv: dict[str, str] = {}
        self.sets: dict[str, set[str]] = {}

    async def get(self, key: str) -> str | None:
        return self.kv.get(key)

    async def set(self, key: str, value: str, ex: int | None = None) -> None:
        del ex
        self.kv[key] = value

    async def delete(self, *keys: str) -> None:
        for key in keys:
            self.kv.pop(key, None)
            self.sets.pop(key, None)

    async def sadd(self, key: str, *values: str) -> None:
        self.sets.setdefault(key, set()).update(values)

    async def smembers(self, key: str) -> AbstractSet[str]:
        return set(self.sets.get(key, set()))

    async def incr(self, key: str) -> int:
        n = int(self.kv.get(key) or 0) + 1
        self.kv[key] = str(n)
        return n

    async def decrby(self, key: str, amount: int) -> int:
        n = int(self.kv.get(key) or 0) - int(amount)
        self.kv[key] = str(n)
        return n

    async def expire(self, key: str, seconds: int) -> None:
        del key, seconds

    async def srem(self, key: str, *values: str) -> None:
        bucket = self.sets.get(key)
        if bucket is not None:
            bucket.difference_update(values)


class FeedCache:
    def __init__(self, redis: Any | None = None) -> None:
        self._redis = redis

    def _page_key(self, tab: str, lang: str, cursor: str) -> str:
        return f"feed:{tab}:{lang}:{cursor or '_'}"

    def _idx_key(self, tab: str, lang: str) -> str:
        return f"feedidx:{tab}:{lang}"

    async def get(self, tab: str, lang: str, cursor: str) -> FeedPage | None:
        if self._redis is None:
            return None
        raw = await self._redis.get(self._page_key(tab, lang, cursor))
        if not raw:
            return None
        return FeedPage.model_validate_json(raw)

    async def set(self, tab: str, lang: str, cursor: str, page: FeedPage, *, ttl_s: int) -> None:
        if self._redis is None:
            return
        key = self._page_key(tab, lang, cursor)
        idx = self._idx_key(tab, lang)
        await self._redis.set(key, page.model_dump_json(), ex=ttl_s)
        await self._redis.sadd(idx, key)
        await self._redis.expire(idx, ttl_s)

    async def drop(self, tab: str, lang: str) -> None:
        if self._redis is None:
            return
        idx = self._idx_key(tab, lang)
        keys = set(await self._redis.smembers(idx))
        if keys:
            await self._redis.delete(*keys, idx)
        else:
            await self._redis.delete(idx)


def to_card(post: Post, lang: Lang, share_base: str) -> Card:
    headline = post.headline_hi if lang == "hi" and post.headline_hi else post.headline
    summary = post.summary_hi if lang == "hi" and post.summary_hi else post.summary
    assert post.published_at is not None
    return Card(
        id=post.id,
        kind=cast(Literal["read", "video", "nxtspot"], post.kind),
        category=post.category,
        headline=headline,
        summary=summary,
        image=_http(post.image_url),
        video_id=post.video_id,
        source=CardSource(name=post.author_credit) if post.author_credit else None,
        url=_http(post.original_url),
        tags=post.tags,
        published_at=post.published_at,
        share_url=f"{share_base}/p/{post.id}",
    )


def to_ad_slot(row: AdCampaign) -> AdSlot | None:
    click = _http(row.click_url)
    if not click:
        return None
    allowed: set[str] = {"sponsored_card", "full_page", "footer", "admob_native"}
    fmt = row.format if row.format in allowed else "sponsored_card"
    return AdSlot(
        format=cast(Literal["admob_native", "sponsored_card", "full_page", "footer"], fmt),
        campaign_id=row.id,
        title=row.title,
        body=row.body,
        creative=_http(row.creative_url),
        click_url=click,
    )


def affected_tabs(post: Post) -> tuple[Tab, ...]:
    tabs: list[Tab] = ["feed"]
    if post.kind == "video":
        tabs.append("video")
    if post.category == "domestic":
        tabs.append("domestic")
    elif post.category == "international":
        tabs.append("international")
    elif post.category == "grassroots":
        tabs.append("nxtspot")
    return tuple(tabs)


def interleave(
    cards: list[Card],
    *,
    ads: list[AdSlot],
    nxtspot: list[Card],
    ad_every: int,
    nxtspot_every: int,
    tab: Tab,
) -> list[Card | AdSlot]:
    if tab != "feed":
        return list(cards)
    out: list[Card | AdSlot] = []
    ad_i = 0
    nx_i = 0
    for content, card in enumerate(cards, start=1):
        out.append(card)
        if ad_every > 0 and ads and content % ad_every == 0:
            out.append(ads[ad_i % len(ads)])
            ad_i += 1
        if nxtspot_every > 0 and nxtspot and content % nxtspot_every == 0:
            out.append(nxtspot[nx_i % len(nxtspot)])
            nx_i += 1
    return out


async def build_feed_page(
    session: AsyncSession,
    settings: Settings,
    *,
    tab: Tab,
    lang: Lang,
    cursor: str | None,
) -> FeedPage:
    after = decode_cursor(cursor) if cursor else None
    limit = settings.feed_page_size
    category, kind = _TAB[tab]
    exclude_kinds = ("nxtspot",) if tab == "feed" else None
    exclude_categories = ("grassroots",) if tab == "feed" else None
    rows = await posts_repo.list_published(
        session,
        category=category,
        kind=kind,
        after=after,
        limit=limit + 1,
        exclude_kinds=exclude_kinds,
        exclude_categories=exclude_categories,
    )
    has_more = len(rows) > limit
    rows = rows[:limit]
    share_base = settings.cdn_base_url or "https://cricit.app"
    items: list[Card | AdSlot] = [to_card(p, lang, share_base) for p in rows]
    if tab == "feed":
        live = await ads_repo.list_live(session, now=datetime.now(UTC))
        ads = [slot for row in live if (slot := to_ad_slot(row))]
        nxt_rows = await posts_repo.list_published(
            session,
            category="grassroots",
            kind=None,
            after=None,
            limit=max(4, limit // 4),
        )
        nxt = [to_card(p, lang, share_base) for p in nxt_rows]
        items = interleave(
            [c for c in items if isinstance(c, Card)],
            ads=ads,
            nxtspot=nxt,
            ad_every=settings.ad_every_n_cards,
            nxtspot_every=settings.nxtspot_every_n_cards,
            tab=tab,
        )
    next_cursor = None
    if has_more and rows and rows[-1].published_at:
        next_cursor = encode_cursor(rows[-1].published_at, rows[-1].id)
    return FeedPage(items=list(items), next_cursor=next_cursor)


async def get_feed(
    session: AsyncSession,
    settings: Settings,
    *,
    tab: Tab,
    lang: Lang,
    cursor: str | None,
    redis: Any | None = None,
    cache: FeedCache | None = None,
) -> FeedPage:
    store = cache if cache is not None else FeedCache(redis)
    try:
        hit = await store.get(tab, lang, cursor or "")
    except Exception:
        hit = None
    if hit is not None:
        return hit
    page = await build_feed_page(session, settings, tab=tab, lang=lang, cursor=cursor)
    if not cursor:
        with contextlib.suppress(Exception):
            await store.set(tab, lang, "", page, ttl_s=settings.feed_cache_ttl_s)
    return page
