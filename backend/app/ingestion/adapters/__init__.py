"""Pick the adapter that matches a source row (T10, T11, T17)."""

from __future__ import annotations

from app.ingestion.adapters.html import HtmlAdapter
from app.ingestion.adapters.rss import RssAdapter
from app.ingestion.adapters.sitemap import SitemapAdapter
from app.ingestion.adapters.twitter import TwitterAdapter
from app.ingestion.adapters.youtube import YoutubeAdapter

FETCHABLE = frozenset({"rss", "html", "sitemap", "youtube", "twitter", "x"})


def adapter_for(
    kind: str | None,
) -> RssAdapter | HtmlAdapter | SitemapAdapter | YoutubeAdapter | TwitterAdapter | None:
    if kind == "rss":
        return RssAdapter()
    if kind == "html":
        return HtmlAdapter()
    if kind == "sitemap":
        return SitemapAdapter()
    if kind == "youtube":
        return YoutubeAdapter()
    if kind in ("twitter", "x"):
        return TwitterAdapter()
    return None
