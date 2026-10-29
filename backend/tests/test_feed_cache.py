"""T16: feed interleaving, Redis cache, Cache-Control, Hindi fallback.

Callers: pytest. Modules: app.services.feed, app.services.publish.
API: GET /v1/feed, GET /v1/config. Schema: FeedPage, Card, AdSlot.
User: "try focusing on them and try building it."
"""

from datetime import UTC, datetime, timedelta
from time import perf_counter
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.models import AdCampaign, Post
from app.schemas.feed import AdSlot, Card, FeedPage
from app.services.feed import (
    FEED_CACHE_CONTROL,
    FakeRedis,
    FeedCache,
    affected_tabs,
    get_feed,
    interleave,
    to_ad_slot,
    to_card,
)
from app.services.publish import rebuild_after_publish

NOW = datetime(2026, 10, 29, 12, tzinfo=UTC)
SHARE = "https://cricit.app"


def _card(n: int, *, kind: str = "read") -> Card:
    pid = uuid4()
    return Card(
        id=pid,
        kind=kind,  # type: ignore[arg-type]
        category="grassroots" if kind == "nxtspot" else "international",
        headline=f"Story {n}",
        summary="Summary",
        published_at=NOW,
        share_url=f"{SHARE}/p/{pid}",
    )


def _ad(n: int) -> AdSlot:
    return AdSlot(
        format="sponsored_card",
        campaign_id=uuid4(),
        title=f"Ad {n}",
        click_url="https://example.com/ad",
        creative="https://cdn.cricit.app/ads/x.png",
    )


def test_interleave_puts_ad_every_6_and_nxtspot_every_8() -> None:
    cards = [_card(i) for i in range(1, 17)]
    ads = [_ad(1), _ad(2)]
    nxt = [_card(90, kind="nxtspot"), _card(91, kind="nxtspot")]
    out = interleave(cards, ads=ads, nxtspot=nxt, ad_every=6, nxtspot_every=8, tab="feed")
    content_idx = 0
    for item in out:
        if item.kind in {"read", "video"}:
            content_idx += 1
        if item.kind == "ad":
            assert content_idx % 6 == 0
        if item.kind == "nxtspot":
            assert content_idx % 8 == 0
    assert any(item.kind == "ad" for item in out)
    assert any(item.kind == "nxtspot" for item in out)


def test_video_and_category_tabs_are_not_interleaved() -> None:
    cards = [_card(i) for i in range(12)]
    mixed = interleave(
        cards,
        ads=[_ad(1)],
        nxtspot=[_card(1, kind="nxtspot")],
        ad_every=6,
        nxtspot_every=8,
        tab="video",
    )
    assert [c.kind for c in mixed] == ["read"] * 12
    domestic = interleave(
        cards,
        ads=[_ad(1)],
        nxtspot=[_card(1, kind="nxtspot")],
        ad_every=6,
        nxtspot_every=8,
        tab="domestic",
    )
    assert len(domestic) == 12


def test_missing_ads_or_nxtspot_skips_the_slot() -> None:
    cards = [_card(i) for i in range(16)]
    out = interleave(cards, ads=[], nxtspot=[], ad_every=6, nxtspot_every=8, tab="feed")
    assert [c.kind for c in out] == ["read"] * 16


def test_zero_interval_disables_inserts() -> None:
    cards = [_card(i) for i in range(12)]
    out = interleave(
        cards,
        ads=[_ad(1)],
        nxtspot=[_card(1, kind="nxtspot")],
        ad_every=0,
        nxtspot_every=0,
        tab="feed",
    )
    assert len(out) == 12


def test_to_card_falls_back_to_english_when_hindi_missing() -> None:
    post = Post(
        id=uuid4(),
        kind="read",
        status="published",
        category="international",
        headline="Gill 104 keeps India in front at Perth",
        summary="A short teaser.",
        headline_hi=None,
        summary_hi=None,
        published_at=NOW,
        tags=[],
    )
    card = to_card(post, "hi", SHARE)
    assert card.headline.startswith("Gill")
    assert card.summary == "A short teaser."


def test_to_card_omits_invalid_image_and_url() -> None:
    post = Post(
        id=uuid4(),
        kind="read",
        status="published",
        category="international",
        headline="Gill 104",
        summary="Teaser",
        image_url="not-a-url",
        original_url="javascript:alert(1)",
        published_at=NOW,
        tags=[],
    )
    card = to_card(post, "en", SHARE)
    assert card.image is None
    assert card.url is None


def test_to_card_uses_hindi_when_present() -> None:
    post = Post(
        id=uuid4(),
        kind="read",
        status="published",
        category="international",
        headline="Gill 104",
        summary="Teaser",
        headline_hi="गिल की 104",
        summary_hi="संक्षेप",
        published_at=NOW,
        tags=[],
    )
    card = to_card(post, "hi", SHARE)
    assert card.headline == "गिल की 104"
    assert card.summary == "संक्षेप"


def test_affected_tabs_include_feed_and_category() -> None:
    post = Post(
        kind="read",
        status="published",
        category="domestic",
        headline="x",
        summary="y",
        published_at=NOW,
        tags=[],
    )
    assert affected_tabs(post) == ("feed", "domestic")
    post.kind = "video"
    post.category = "international"
    assert "video" in affected_tabs(post)
    assert "feed" in affected_tabs(post)


def test_to_ad_slot_maps_a_live_campaign() -> None:
    row = AdCampaign(
        advertiser="Kineto Sports",
        format="sponsored_card",
        creative_url="https://cdn.cricit.app/ads/kineto.png",
        click_url="https://example.com/kineto",
        title="Grip that lasts a whole Test",
        body="Sponsored",
        start_at=NOW - timedelta(days=1),
        end_at=NOW + timedelta(days=30),
        frequency=6,
        is_active=True,
    )
    slot = to_ad_slot(row)
    assert slot is not None
    assert slot.kind == "ad"
    assert slot.format == "sponsored_card"
    assert slot.title == "Grip that lasts a whole Test"


def test_to_ad_slot_skips_invalid_click_url() -> None:
    row = AdCampaign(
        advertiser="Bad",
        format="sponsored_card",
        creative_url="https://cdn.cricit.app/ads/x.png",
        click_url="javascript:alert(1)",
        title="Nope",
        start_at=NOW - timedelta(days=1),
        end_at=NOW + timedelta(days=30),
        is_active=True,
    )
    assert to_ad_slot(row) is None


@pytest.mark.asyncio
async def test_feed_cache_round_trip_and_invalidate() -> None:
    cache = FeedCache(FakeRedis())
    page = FeedPage(items=[], next_cursor="abc")
    await cache.set("feed", "en", "", page, ttl_s=60)
    hit = await cache.get("feed", "en", "")
    assert hit is not None
    assert hit.next_cursor == "abc"
    await cache.drop("feed", "en")
    assert await cache.get("feed", "en", "") is None


@pytest.mark.asyncio
async def test_rebuild_warms_first_pages(monkeypatch: pytest.MonkeyPatch) -> None:
    cache = FeedCache(FakeRedis())
    built: list[str] = []

    async def fake_build(session: object, settings: Settings, **kwargs: object) -> FeedPage:
        tab = str(kwargs["tab"])
        lang = str(kwargs["lang"])
        cursor = kwargs.get("cursor")
        built.append(f"{tab}:{lang}:{cursor}")
        nxt = "c1" if cursor is None else None
        return FeedPage(items=[], next_cursor=nxt)

    monkeypatch.setattr("app.services.publish.build_feed_page", fake_build)
    post = Post(
        kind="read",
        status="published",
        category="international",
        headline="x",
        summary="y",
        published_at=NOW,
        tags=[],
    )
    await rebuild_after_publish(
        None,  # type: ignore[arg-type]
        post,
        settings=Settings(feed_cache_pages=3),
        cache=cache,
    )
    assert any(item.startswith("feed:en:") for item in built)
    assert any(item.startswith("international:hi:") for item in built)
    assert await cache.get("feed", "en", "") is not None


def test_interleave_page_is_well_under_150ms() -> None:
    cards = [_card(i) for i in range(20)]
    ads = [_ad(i) for i in range(4)]
    nxt = [_card(100 + i, kind="nxtspot") for i in range(4)]
    t0 = perf_counter()
    for _ in range(500):
        interleave(cards, ads=ads, nxtspot=nxt, ad_every=6, nxtspot_every=8, tab="feed")
    elapsed_ms = (perf_counter() - t0) * 1000 / 500
    assert elapsed_ms < 150


@pytest.mark.asyncio
async def test_get_feed_caches_first_page_only(monkeypatch: pytest.MonkeyPatch) -> None:
    cache = FeedCache(FakeRedis())
    cursors: list[object] = []

    async def fake_build(session: object, settings: Settings, **kwargs: object) -> FeedPage:
        del session, settings
        cursors.append(kwargs.get("cursor"))
        return FeedPage(items=[], next_cursor="n1")

    monkeypatch.setattr("app.services.feed.build_feed_page", fake_build)
    settings = Settings()
    first = await get_feed(
        None,  # type: ignore[arg-type]
        settings,
        tab="feed",
        lang="en",
        cursor=None,
        cache=cache,
    )
    second = await get_feed(
        None,  # type: ignore[arg-type]
        settings,
        tab="feed",
        lang="en",
        cursor="n1",
        cache=cache,
    )
    assert first.next_cursor == "n1"
    assert second.next_cursor == "n1"
    assert await cache.get("feed", "en", "") is not None
    assert await cache.get("feed", "en", "n1") is None
    assert cursors == [None, "n1"]


def test_feed_route_sends_cache_control(monkeypatch: pytest.MonkeyPatch) -> None:
    async def fake_get_feed(*args: object, **kwargs: object) -> FeedPage:
        return FeedPage(items=[], next_cursor=None)

    monkeypatch.setattr("app.api.v1.routes.feed_service.get_feed", fake_get_feed)
    from app.main import create_app

    client = TestClient(create_app())
    r = client.get("/v1/feed")
    assert r.status_code == 200
    assert r.headers["Cache-Control"] == FEED_CACHE_CONTROL


def test_config_exposes_interleave_settings() -> None:
    from app.main import create_app

    client = TestClient(create_app())
    r = client.get("/v1/config")
    assert r.status_code == 200
    body = r.json()
    assert body["ad_every_n_cards"] == 6
    assert body["nxtspot_every_n_cards"] == 8
