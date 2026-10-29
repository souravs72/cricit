"""T11: robots.txt cache (24 h) and 1 request/second per host.

Callers: pytest. Module: app.ingestion.polite.
User: "Please implement the next things"
"""

from urllib.parse import urlsplit

import httpx
import pytest

from app.core.errors import ValidationFailed
from app.ingestion import polite


@pytest.fixture(autouse=True)
def _reset_polite() -> None:
    polite.reset_for_tests()


def test_robots_cache_expires_after_24h() -> None:
    parser = polite.robots_from_text("User-agent: *\nAllow: /\n")
    polite.cache_put("www.bcci.tv", parser, now=1_000.0)
    assert polite.cache_get("www.bcci.tv", now=1_000.0) is parser
    assert polite.cache_get("www.bcci.tv", now=1_000.0 + polite.ROBOTS_TTL_SEC + 1) is None


def test_robots_url_is_origin_robots_txt() -> None:
    assert (
        polite.robots_url_for("https://www.bcci.tv/news/gill") == "https://www.bcci.tv/robots.txt"
    )


@pytest.mark.asyncio
async def test_throttle_waits_under_one_second() -> None:
    slept: list[float] = []

    async def fake_sleep(seconds: float) -> None:
        slept.append(seconds)

    await polite.wait_host("www.bcci.tv", now=10.0, sleep=fake_sleep)
    await polite.wait_host("www.bcci.tv", now=10.4, sleep=fake_sleep)
    assert slept == [pytest.approx(0.6)]


@pytest.mark.asyncio
async def test_robots_disallow_blocks_listing() -> None:
    with pytest.raises(ValidationFailed, match="disallows"):
        await polite.assert_robots_allows(
            "https://www.bcci.tv/news",
            field="listing_url",
            robots_text="User-agent: *\nDisallow: /news\n",
        )


@pytest.mark.asyncio
async def test_robots_allow_passes() -> None:
    await polite.assert_robots_allows(
        "https://www.bcci.tv/news",
        field="listing_url",
        robots_text="User-agent: *\nAllow: /\n",
    )


@pytest.mark.asyncio
async def test_robots_fetched_once_then_cached() -> None:
    hits: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        hits.append(str(request.url))
        if urlsplit(str(request.url)).path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nAllow: /\n")
        return httpx.Response(404)

    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport, follow_redirects=False) as client:
        await polite.assert_robots_allows(
            "https://www.bcci.tv/news", field="listing_url", client=client
        )
        await polite.assert_robots_allows(
            "https://www.bcci.tv/news/other", field="listing_url", client=client
        )
    assert hits == ["https://www.bcci.tv/robots.txt"]
