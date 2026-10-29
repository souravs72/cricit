"""T11: news sitemap, last 48 h, skip private URLs.

Callers: pytest. Module: SitemapAdapter. User: "Please implement the next things"
"""

from datetime import UTC, datetime
from pathlib import Path

import httpx
import pytest

from app.ingestion.adapters.sitemap import SitemapAdapter
from app.ingestion.polite import reset_for_tests

FIXTURE = Path(__file__).parent / "fixtures" / "sitemap_news.xml"
NOW = datetime(2026, 10, 29, 12, tzinfo=UTC)
CFG = {"kind": "sitemap", "sitemap_url": "https://www.bcci.tv/news-sitemap.xml"}


@pytest.fixture(autouse=True)
def _reset() -> None:
    reset_for_tests()


def test_sitemap_keeps_recent_public_items_only() -> None:
    items = SitemapAdapter.parse_bytes(FIXTURE.read_bytes(), now=NOW)
    assert [i.title for i in items] == ["Gill 104 keeps India in front at Perth"]
    assert items[0].url == "https://www.bcci.tv/news/gill-104-perth"
    assert items[0].published_at is not None


def test_sitemap_malformed_xml_is_empty() -> None:
    assert SitemapAdapter.parse_bytes(b"<not-xml", now=NOW) == []


@pytest.mark.asyncio
async def test_sitemap_fetch_304() -> None:
    xml = FIXTURE.read_bytes()

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nAllow: /\n")
        if request.headers.get("If-None-Match") == '"map1"':
            return httpx.Response(304, headers={"ETag": '"map1"'})
        return httpx.Response(200, content=xml, headers={"ETag": '"map1"'})

    transport = httpx.MockTransport(handler)
    adapter = SitemapAdapter()
    async with httpx.AsyncClient(transport=transport, follow_redirects=False) as client:
        first = await adapter.fetch(CFG, etag=None, last_modified=None, client=client, now=NOW)
        assert first.not_modified is False
        assert len(first.items) == 1
        second = await adapter.fetch(CFG, etag='"map1"', last_modified=None, client=client, now=NOW)
        assert second.not_modified is True
