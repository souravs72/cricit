"""T09: adapter_config is typed per adapter; SSRF is enforced on create.

Callers: pytest. Schemas: SourceCreate, SourcePatch. Route: POST /admin/v1/sources.
User: "Check what is tobe built now into this - build it"
"""

from uuid import uuid4

from pydantic import ValidationError

from app.schemas.newsroom import PostListItem
from app.schemas.sources import SourceCreate, SourcePatch


def test_rss_requires_a_public_feed_url() -> None:
    row = SourceCreate(
        name="ESPNcricinfo",
        type="news",
        adapter="rss",
        adapter_config={"feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"},
        default_category="international",
        trust_level="auto",
    )
    assert row.adapter_config["kind"] == "rss"
    assert row.adapter_config["feed_url"].startswith("https://")


def test_rss_without_feed_url_fails() -> None:
    try:
        SourceCreate(name="No feed", type="news", adapter="rss", adapter_config={})
        raise AssertionError("rss config must require feed_url")
    except ValidationError:
        pass


def test_rss_localhost_is_rejected() -> None:
    try:
        SourceCreate(
            name="SSRF",
            type="news",
            adapter="rss",
            adapter_config={"feed_url": "http://127.0.0.1/rss.xml"},
        )
        raise AssertionError("localhost must fail SSRF checks")
    except ValidationError:
        pass


def test_html_requires_listing_url() -> None:
    row = SourceCreate(
        name="BCCI",
        type="news",
        adapter="html",
        adapter_config={"listing_url": "https://www.bcci.tv/news"},
        default_category="domestic",
        trust_level="review",
    )
    assert row.adapter_config["kind"] == "html"
    assert "item_selector" in row.adapter_config


def test_sitemap_requires_public_url() -> None:
    row = SourceCreate(
        name="BCCI sitemap",
        type="news",
        adapter="sitemap",
        adapter_config={"sitemap_url": "https://www.bcci.tv/news-sitemap.xml"},
    )
    assert row.adapter_config["kind"] == "sitemap"
    try:
        SourceCreate(
            name="Bad sitemap",
            type="news",
            adapter="sitemap",
            adapter_config={"sitemap_url": "http://127.0.0.1/sitemap.xml"},
        )
        raise AssertionError("localhost sitemap must fail SSRF")
    except ValidationError:
        pass


def test_patch_can_pause_without_touching_config() -> None:
    patch = SourcePatch(is_active=False)
    assert patch.is_active is False
    assert patch.adapter_config is None


def test_review_item_carries_possible_duplicate_headline() -> None:
    other = uuid4()
    item = PostListItem(
        id=uuid4(),
        kind="read",
        status="review",
        category="international",
        headline="India lose to Australia in Perth Test",
        author_credit="BBC Sport Cricket",
        published_at=None,
        tags=[],
        possible_duplicate_of=other,
        duplicate_headline="India beat Australia in Perth Test",
    )
    assert item.possible_duplicate_of == other
    assert item.duplicate_headline == "India beat Australia in Perth Test"
