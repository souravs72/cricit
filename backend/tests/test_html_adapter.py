"""T11: HTML listing adapter, BCCI/ICC fixtures, no article body.

Callers: pytest. Module: HtmlAdapter. User: "Please implement the next things"
"""

from pathlib import Path

import httpx
import pytest

from app.core.errors import ValidationFailed
from app.ingestion.adapters.html import HtmlAdapter
from app.ingestion.polite import reset_for_tests

BCCI = Path(__file__).parent / "fixtures" / "html_bcci.html"
ICC = Path(__file__).parent / "fixtures" / "html_icc.html"

BCCI_CFG = {
    "kind": "html",
    "listing_url": "https://www.bcci.tv/news",
    "item_selector": "article.news-card a",
}
ICC_CFG = {
    "kind": "html",
    "listing_url": "https://www.icc-cricket.com/news",
    "item_selector": "a.news-item",
}


@pytest.fixture(autouse=True)
def _reset() -> None:
    reset_for_tests()


def test_bcci_fixture_keeps_headlines_and_public_links() -> None:
    items = HtmlAdapter.parse_bytes(BCCI.read_bytes(), BCCI_CFG)
    titles = [i.title for i in items]
    assert "Gill 104 keeps India in front at Perth" in titles
    assert "England rest Archer for the Oval ODI" in titles
    assert all(i.url.startswith("https://www.bcci.tv/") for i in items)
    assert all("127.0.0.1" not in i.url for i in items)
    gill = next(i for i in items if "Gill" in i.title)
    assert len(gill.extra["summary"].split()) <= 60
    assert "<" not in gill.extra["summary"]


def test_icc_fixture_uses_its_selector() -> None:
    items = HtmlAdapter.parse_bytes(ICC.read_bytes(), ICC_CFG)
    titles = [i.title for i in items]
    assert "ICC announces World Cup draw in Mumbai" in titles
    assert any("Women" in t for t in titles)
    assert all("#" not in i.url for i in items)


def test_html_never_keeps_a_full_article_body() -> None:
    items = HtmlAdapter.parse_bytes(BCCI.read_bytes(), BCCI_CFG)
    for item in items:
        assert len(item.extra["summary"].split()) <= 60


@pytest.mark.asyncio
async def test_html_fetch_respects_robots_and_etag() -> None:
    html = BCCI.read_bytes()
    hits: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        hits.append(f"{request.method} {request.url.path}")
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nAllow: /\n")
        if request.headers.get("If-None-Match") == '"v1"':
            return httpx.Response(304, headers={"ETag": '"v1"'})
        return httpx.Response(200, content=html, headers={"ETag": '"v1"'})

    transport = httpx.MockTransport(handler)
    adapter = HtmlAdapter()
    async with httpx.AsyncClient(transport=transport, follow_redirects=False) as client:
        first = await adapter.fetch(BCCI_CFG, etag=None, last_modified=None, client=client)
        assert first.not_modified is False
        assert len(first.items) == 2
        second = await adapter.fetch(BCCI_CFG, etag='"v1"', last_modified=None, client=client)
        assert second.not_modified is True
        assert second.items == []
    assert "GET /robots.txt" in hits


@pytest.mark.asyncio
async def test_html_fetch_blocked_by_robots() -> None:
    adapter = HtmlAdapter()
    with pytest.raises(ValidationFailed, match="disallows"):
        await adapter.fetch(
            BCCI_CFG,
            etag=None,
            last_modified=None,
            robots_text="User-agent: *\nDisallow: /news\n",
        )
