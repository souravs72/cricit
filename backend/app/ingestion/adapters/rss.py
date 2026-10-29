"""RSS/Atom adapter with conditional GET, so unchanged feeds cost one 304.

Callers: ingest.fetch_and_store, sources.test_fetch, tests/test_ingest.py.
API: POST /admin/v1/sources/{id}/test; worker fetch_source.
Schema: RawItem + FetchResult (etag, last_modified).
"""

from datetime import UTC, datetime
from html import unescape
from re import compile as re_compile
from time import struct_time
from typing import Any

import feedparser
import httpx

from app.core.errors import ValidationFailed
from app.ingestion.adapters.base import FetchResult, RawItem
from app.ingestion.ssrf import assert_public_http_url, assert_safe_to_fetch

USER_AGENT = "CRICITBot/1.0 (+https://cricit.app/bot)"
TIMEOUT = httpx.Timeout(15.0, connect=5.0)
_TAGS = re_compile(r"<[^>]+>")
_WS = re_compile(r"\s+")


def _to_dt(value: struct_time | None) -> datetime | None:
    if not value:
        return None
    return datetime(*value[:6], tzinfo=UTC)


def _teaser(raw: str | None) -> str:
    text = _WS.sub(" ", unescape(_TAGS.sub(" ", raw or ""))).strip()
    return " ".join(text.split()[:60])


class RssAdapter:
    @staticmethod
    def parse_bytes(content: bytes) -> list[RawItem]:
        parsed = feedparser.parse(content)
        items: list[RawItem] = []
        for entry in parsed.entries:
            link = entry.get("link")
            title = (entry.get("title") or "").strip()
            if not link or not title:
                continue
            try:
                link = assert_public_http_url(str(link), field="url")
            except ValidationFailed:
                continue
            image = None
            media = entry.get("media_content") or entry.get("media_thumbnail") or []
            if media:
                raw_image = media[0].get("url")
                if raw_image:
                    try:
                        image = assert_public_http_url(str(raw_image), field="url")
                    except ValidationFailed:
                        image = None
            items.append(
                RawItem(
                    url=link,
                    title=title,
                    published_at=_to_dt(
                        entry.get("published_parsed") or entry.get("updated_parsed")
                    ),
                    image_url=image,
                    extra={"summary": _teaser(entry.get("summary") or entry.get("description"))},
                )
            )
        return items

    async def fetch(
        self,
        config: dict[str, Any],
        *,
        etag: str | None,
        last_modified: str | None,
        client: httpx.AsyncClient | None = None,
    ) -> FetchResult:
        resolve = client is None

        def _guard(request: httpx.Request) -> None:
            url = str(request.url)
            if resolve:
                assert_safe_to_fetch(url, field="feed_url")
            else:
                assert_public_http_url(url, field="feed_url")

        feed_url = (
            assert_safe_to_fetch(str(config["feed_url"]), field="feed_url")
            if resolve
            else assert_public_http_url(str(config["feed_url"]), field="feed_url")
        )
        headers = {"User-Agent": USER_AGENT}
        if etag:
            headers["If-None-Match"] = etag
        if last_modified:
            headers["If-Modified-Since"] = last_modified
        own = client is None
        http = client or httpx.AsyncClient(
            timeout=TIMEOUT,
            follow_redirects=True,
            event_hooks={"request": [_guard]},
        )
        try:
            resp = await http.get(feed_url, headers=headers)
        finally:
            if own:
                await http.aclose()
        if resp.status_code == 304:
            return FetchResult(items=[], etag=etag, last_modified=last_modified, not_modified=True)
        resp.raise_for_status()
        return FetchResult(
            items=self.parse_bytes(resp.content),
            etag=resp.headers.get("ETag"),
            last_modified=resp.headers.get("Last-Modified"),
        )
