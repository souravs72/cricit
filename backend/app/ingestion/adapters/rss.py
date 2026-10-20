"""RSS/Atom adapter with conditional GET, so unchanged feeds cost one 304."""

from datetime import UTC, datetime
from time import struct_time
from typing import Any

import feedparser
import httpx

from app.ingestion.adapters.base import FetchResult, RawItem

USER_AGENT = "CRICITBot/1.0 (+https://cricit.app/bot)"
TIMEOUT = httpx.Timeout(15.0, connect=5.0)


def _to_dt(value: struct_time | None) -> datetime | None:
    if not value:
        return None
    return datetime(*value[:6], tzinfo=UTC)


class RssAdapter:
    async def fetch(
        self, config: dict[str, Any], *, etag: str | None, last_modified: str | None
    ) -> FetchResult:
        headers = {"User-Agent": USER_AGENT}
        if etag:
            headers["If-None-Match"] = etag
        if last_modified:
            headers["If-Modified-Since"] = last_modified
        async with httpx.AsyncClient(timeout=TIMEOUT, follow_redirects=True) as client:
            resp = await client.get(config["feed_url"], headers=headers)
        if resp.status_code == 304:
            return FetchResult(items=[], etag=etag, last_modified=last_modified, not_modified=True)
        resp.raise_for_status()
        parsed = feedparser.parse(resp.content)
        items = []
        for entry in parsed.entries:
            link = entry.get("link")
            title = (entry.get("title") or "").strip()
            if not link or not title:
                continue
            image = None
            media = entry.get("media_content") or entry.get("media_thumbnail") or []
            if media:
                image = media[0].get("url")
            items.append(
                RawItem(
                    url=link,
                    title=title,
                    published_at=_to_dt(
                        entry.get("published_parsed") or entry.get("updated_parsed")
                    ),
                    image_url=image,
                )
            )
        return FetchResult(
            items=items,
            etag=resp.headers.get("ETag"),
            last_modified=resp.headers.get("Last-Modified"),
        )
