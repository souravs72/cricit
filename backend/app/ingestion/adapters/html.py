"""HTML listing adapter: CSS selectors from adapter_config, titles + links only (T11).

Callers: ingest.fetch_and_store, sources.test_fetch, tests/test_html_adapter.py.
Never stores article bodies.
"""

from __future__ import annotations

from html import unescape
from re import compile as re_compile
from typing import Any
from urllib.parse import urljoin

import httpx
from selectolax.lexbor import LexborHTMLParser

from app.core.errors import ValidationFailed
from app.ingestion.adapters.base import FetchResult, RawItem
from app.ingestion.polite import assert_robots_allows, http_get
from app.ingestion.ssrf import assert_public_http_url

DEFAULT_ITEM_SELECTOR = "article a[href], a[href*='/news/']"
MIN_TITLE_LEN = 12
MAX_ITEMS = 50
_TAGS = re_compile(r"<[^>]+>")
_WS = re_compile(r"\s+")


def _teaser(raw: str | None) -> str:
    text = _WS.sub(" ", unescape(_TAGS.sub(" ", raw or ""))).strip()
    return " ".join(text.split()[:60])


def _href(node: Any) -> str | None:
    href = (node.attributes or {}).get("href")
    if href:
        return str(href)
    link = node.css_first("a[href]")
    if link is None:
        return None
    value = (link.attributes or {}).get("href")
    return str(value) if value else None


def _title(node: Any, title_selector: str | None) -> str:
    if title_selector:
        sub = node.css_first(title_selector)
        if sub is not None:
            return _teaser(sub.text(separator=" ", strip=True))
    link = node if (node.attributes or {}).get("href") else node.css_first("a[href]")
    target = link or node
    return _teaser(target.text(separator=" ", strip=True))


class HtmlAdapter:
    @staticmethod
    def parse_bytes(content: bytes, config: dict[str, Any]) -> list[RawItem]:
        listing_url = str(config["listing_url"])
        item_selector = str(config.get("item_selector") or DEFAULT_ITEM_SELECTOR)
        title_selector = config.get("title_selector")
        title_sel = title_selector if isinstance(title_selector, str) and title_selector else None
        tree = LexborHTMLParser(content)
        try:
            nodes = tree.css(item_selector)
        except Exception as exc:
            raise ValidationFailed("Invalid CSS selector", field="item_selector") from exc
        items: list[RawItem] = []
        seen: set[str] = set()
        for node in nodes:
            raw_href = _href(node)
            href_l = (raw_href or "").lower()
            if not raw_href or raw_href.startswith("#") or href_l.startswith("javascript:"):
                continue
            try:
                url = assert_public_http_url(urljoin(listing_url, raw_href), field="url")
            except ValidationFailed:
                continue
            if url in seen or url.rstrip("/") == listing_url.rstrip("/"):
                continue
            title = _title(node, title_sel)
            if len(title) < MIN_TITLE_LEN:
                continue
            seen.add(url)
            items.append(
                RawItem(
                    url=url,
                    title=title[:160],
                    published_at=None,
                    extra={"summary": title},
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
    ) -> FetchResult:
        listing_url = str(config["listing_url"])
        await assert_robots_allows(
            listing_url, field="listing_url", client=client, robots_text=robots_text
        )
        resp = await http_get(
            listing_url,
            field="listing_url",
            client=client,
            etag=etag,
            last_modified=last_modified,
        )
        if resp.status_code == 304:
            return FetchResult(items=[], etag=etag, last_modified=last_modified, not_modified=True)
        resp.raise_for_status()
        return FetchResult(
            items=self.parse_bytes(resp.content, config),
            etag=resp.headers.get("ETag"),
            last_modified=resp.headers.get("Last-Modified"),
        )
