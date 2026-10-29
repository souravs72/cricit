"""T09: adapter_config is typed per adapter; SSRF is enforced on create.

Callers: pytest. Schemas: SourceCreate, SourcePatch. Route: POST /admin/v1/sources.
User: "Check what is tobe built now into this - build it"
"""

from pydantic import ValidationError

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


def test_patch_can_pause_without_touching_config() -> None:
    patch = SourcePatch(is_active=False)
    assert patch.is_active is False
    assert patch.adapter_config is None
