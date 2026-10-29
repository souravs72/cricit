"""Pick the adapter that matches a source row (T10, T11)."""

from __future__ import annotations

from app.ingestion.adapters.html import HtmlAdapter
from app.ingestion.adapters.rss import RssAdapter
from app.ingestion.adapters.sitemap import SitemapAdapter

FETCHABLE = frozenset({"rss", "html", "sitemap"})


def adapter_for(kind: str | None) -> RssAdapter | HtmlAdapter | SitemapAdapter | None:
    if kind == "rss":
        return RssAdapter()
    if kind == "html":
        return HtmlAdapter()
    if kind == "sitemap":
        return SitemapAdapter()
    return None
