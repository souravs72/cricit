"""robots.txt (24 h cache) and 1 request/second per host for HTML/sitemap fetches (T11).

Callers: HtmlAdapter, SitemapAdapter, tests/test_polite.py.
Never used as a public API.
"""

from __future__ import annotations

import asyncio
import time
from collections.abc import Awaitable, Callable
from urllib.parse import urlsplit
from urllib.robotparser import RobotFileParser

import httpx

from app.core.errors import ValidationFailed
from app.ingestion.ssrf import assert_public_http_url, assert_safe_to_fetch

USER_AGENT = "CRICITBot/1.0 (+https://cricit.app/bot)"
TIMEOUT = httpx.Timeout(15.0, connect=5.0)
ROBOTS_TTL_SEC = 86_400
MIN_INTERVAL_SEC = 1.0

_robots: dict[str, tuple[float, RobotFileParser]] = {}
_last_request: dict[str, float] = {}
_host_locks: dict[str, asyncio.Lock] = {}


def reset_for_tests() -> None:
    _robots.clear()
    _last_request.clear()
    _host_locks.clear()


def robots_from_text(text: str) -> RobotFileParser:
    parser = RobotFileParser()
    parser.parse(text.splitlines())
    return parser


def cache_put(host: str, parser: RobotFileParser, *, now: float | None = None) -> None:
    _robots[host.lower()] = (now if now is not None else time.monotonic(), parser)


def cache_get(
    host: str, *, now: float | None = None, ttl: float = ROBOTS_TTL_SEC
) -> RobotFileParser | None:
    entry = _robots.get(host.lower())
    if entry is None:
        return None
    stored, parser = entry
    clock = now if now is not None else time.monotonic()
    if clock - stored > ttl:
        _robots.pop(host.lower(), None)
        return None
    return parser


def robots_url_for(page_url: str) -> str:
    parts = urlsplit(page_url)
    return f"{parts.scheme}://{parts.netloc}/robots.txt"


def _lock(host: str) -> asyncio.Lock:
    lock = _host_locks.get(host)
    if lock is None:
        lock = asyncio.Lock()
        _host_locks[host] = lock
    return lock


async def wait_host(
    host: str,
    *,
    now: float | None = None,
    interval: float = MIN_INTERVAL_SEC,
    sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
) -> None:
    clock = time.monotonic() if now is None else now
    async with _lock(host):
        last = _last_request.get(host)
        if last is not None:
            delay = interval - (clock - last)
            if delay > 0:
                await sleep(delay)
                clock = time.monotonic() if now is None else clock + delay
        _last_request[host] = clock


def make_client(*, resolve: bool, field: str) -> httpx.AsyncClient:
    def _guard(request: httpx.Request) -> None:
        url = str(request.url)
        if resolve:
            assert_safe_to_fetch(url, field=field)
        else:
            assert_public_http_url(url, field=field)

    return httpx.AsyncClient(
        timeout=TIMEOUT,
        follow_redirects=True,
        event_hooks={"request": [_guard]},
        headers={"User-Agent": USER_AGENT},
    )


async def http_get(
    url: str,
    *,
    field: str,
    client: httpx.AsyncClient | None = None,
    etag: str | None = None,
    last_modified: str | None = None,
) -> httpx.Response:
    resolve = client is None
    checked = (
        assert_safe_to_fetch(url, field=field)
        if resolve
        else assert_public_http_url(url, field=field)
    )
    headers = {"User-Agent": USER_AGENT}
    if etag:
        headers["If-None-Match"] = etag
    if last_modified:
        headers["If-Modified-Since"] = last_modified
    own = client is None
    http = client or make_client(resolve=True, field=field)
    try:
        if own:
            await wait_host(urlsplit(checked).netloc.lower())
        return await http.get(checked, headers=headers)
    finally:
        if own:
            await http.aclose()


async def assert_robots_allows(
    url: str,
    *,
    field: str,
    client: httpx.AsyncClient | None = None,
    robots_text: str | None = None,
) -> None:
    parser: RobotFileParser | None
    if robots_text is not None:
        parser = robots_from_text(robots_text)
    else:
        host = urlsplit(url).netloc.lower()
        parser = cache_get(host)
        if parser is None:
            robots_url = robots_url_for(url)
            try:
                resp = await http_get(robots_url, field=field, client=client)
            except ValidationFailed:
                raise
            except Exception as exc:
                raise ValidationFailed("robots.txt unavailable", field=field) from exc
            if resp.status_code == 404:
                parser = robots_from_text("User-agent: *\nAllow: /\n")
            elif resp.status_code >= 400:
                raise ValidationFailed("robots.txt unavailable", field=field)
            else:
                parser = robots_from_text(resp.text)
            cache_put(host, parser)
    if parser is None or not parser.can_fetch(USER_AGENT, url):
        raise ValidationFailed("robots.txt disallows this path", field=field)
