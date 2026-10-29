"""Google news sitemap adapter; keeps entries from the last 48 hours (T11).

Callers: ingest.fetch_and_store, sources.test_fetch, tests/test_sitemap_adapter.py.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any
from xml.etree.ElementTree import ParseError, fromstring

import httpx

from app.core.errors import ValidationFailed
from app.ingestion.adapters.base import FetchResult, RawItem
from app.ingestion.polite import assert_robots_allows, http_get
from app.ingestion.ssrf import assert_public_http_url

MAX_AGE = timedelta(hours=48)
MAX_BYTES = 2_000_000
MAX_ITEMS = 80


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _parse_dt(raw: str | None) -> datetime | None:
    if not raw:
        return None
    text = raw.strip().replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


class SitemapAdapter:
    @staticmethod
    def parse_bytes(content: bytes, *, now: datetime | None = None) -> list[RawItem]:
        if len(content) > MAX_BYTES:
            return []
        clock = now or datetime.now(UTC)
        try:
            root = fromstring(content)  # noqa: S314
        except ParseError:
            return []
        items: list[RawItem] = []
        seen: set[str] = set()
        for url_el in root.iter():
            if _local(url_el.tag) != "url":
                continue
            loc = ""
            title = ""
            published: datetime | None = None
            for child in list(url_el):
                name = _local(child.tag)
                if name == "loc":
                    loc = (child.text or "").strip()
                elif name == "lastmod" and published is None:
                    published = _parse_dt(child.text)
                elif name == "news":
                    for news_child in list(child):
                        nname = _local(news_child.tag)
                        if nname == "title":
                            title = (news_child.text or "").strip()
                        elif nname == "publication_date":
                            published = _parse_dt(news_child.text)
            if not loc or not title:
                continue
            if published is None or clock - published > MAX_AGE:
                continue
            try:
                url = assert_public_http_url(loc, field="url")
            except ValidationFailed:
                continue
            if url in seen:
                continue
            seen.add(url)
            items.append(
                RawItem(
                    url=url,
                    title=title[:160],
                    published_at=published,
                    extra={"summary": title[:400]},
                )
            )
            if len(items) >= MAX_ITEMS:
                break
        return items

    async def fetch(
        self,
        config: dict[str, Any],
        *,
        etag: str | None,
        last_modified: str | None,
        client: httpx.AsyncClient | None = None,
        robots_text: str | None = None,
        now: datetime | None = None,
    ) -> FetchResult:
        sitemap_url = str(config["sitemap_url"])
        await assert_robots_allows(
            sitemap_url, field="sitemap_url", client=client, robots_text=robots_text
        )
        resp = await http_get(
            sitemap_url,
            field="sitemap_url",
            client=client,
            etag=etag,
            last_modified=last_modified,
        )
        if resp.status_code == 304:
            return FetchResult(items=[], etag=etag, last_modified=last_modified, not_modified=True)
        resp.raise_for_status()
        return FetchResult(
            items=self.parse_bytes(resp.content, now=now),
            etag=resp.headers.get("ETag"),
            last_modified=resp.headers.get("Last-Modified"),
        )
