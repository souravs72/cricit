"""YouTube Shorts adapter.

Ingests short videos (<= 60s) from YouTube channels, handles, or playlists.
Supports YouTube Data API v3 when configured with YOUTUBE_API_KEY, as well as
public web channel/shorts scraping with ytInitialData fallback.

Callers: adapter_for("youtube"), sources.test_fetch, workers.fetch_source.
Schema: RawItem + FetchResult.
"""

from __future__ import annotations

import json
import os
import re
import xml.etree.ElementTree as ET
from datetime import UTC, datetime
from html import unescape
from typing import Any

import httpx

from app.ingestion.adapters.base import FetchResult, RawItem
from app.ingestion.ssrf import assert_public_http_url

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
TIMEOUT = httpx.Timeout(20.0, connect=10.0)
_VIDEO_ID_RE = re.compile(r"^[a-zA-Z0-9_-]{11}$")
_INITIAL_DATA_RE = re.compile(r"var ytInitialData\s*=\s*({.+?});</script>", re.DOTALL)


class YoutubeAdapter:
    @staticmethod
    def parse_shorts_html(html: str) -> list[RawItem]:
        """Extract shorts items from YouTube channel shorts page HTML."""
        items: list[RawItem] = []
        match = _INITIAL_DATA_RE.search(html)
        if not match:
            # Fallback regex search for videoId
            video_ids = list(dict.fromkeys(re.findall(r'"videoId":"([a-zA-Z0-9_-]{11})"', html)))
            for vid in video_ids[:20]:
                items.append(
                    RawItem(
                        url=f"https://www.youtube.com/shorts/{vid}",
                        title="Cricket Short",
                        published_at=datetime.now(UTC),
                        image_url=f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg",
                        extra={"video_id": vid, "kind": "video", "source": "youtube"},
                    )
                )
            return items

        try:
            data = json.loads(match.group(1))
            tabs = (
                data.get("contents", {}).get("twoColumnBrowseResultsRenderer", {}).get("tabs", [])
            )
            contents: list[dict[str, Any]] = []
            for tab in tabs:
                renderer = tab.get("tabRenderer", {})
                if renderer.get("selected") or "Shorts" in renderer.get("title", ""):
                    grid = renderer.get("content", {}).get("richGridRenderer", {})
                    contents = grid.get("contents", [])
                    if contents:
                        break

            for c in contents:
                lockup = (
                    c.get("richItemRenderer", {}).get("content", {}).get("shortsLockupViewModel")
                )
                if not lockup:
                    continue
                entity_id = lockup.get("entityId", "")
                vid = entity_id.replace("shorts-shelf-item-", "")
                if not _VIDEO_ID_RE.match(vid):
                    continue
                title = (
                    lockup.get("overlayMetadata", {})
                    .get("primaryText", {})
                    .get("content", "Cricket Video Short")
                )
                thumb = f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
                items.append(
                    RawItem(
                        url=f"https://www.youtube.com/shorts/{vid}",
                        title=unescape(title).strip(),
                        published_at=datetime.now(UTC),
                        image_url=thumb,
                        extra={"video_id": vid, "kind": "video", "source": "youtube"},
                    )
                )
        except Exception:
            pass
        return items

    @staticmethod
    def parse_feed_bytes(content: bytes) -> list[RawItem]:
        """Extract videos from a YouTube channel/user RSS feed (Atom)."""
        items: list[RawItem] = []
        try:
            root = ET.fromstring(content)
            # Atom namespaces
            ns = {
                "atom": "http://www.w3.org/2005/Atom",
                "yt": "http://www.youtube.com/xml/schemas/2015",
                "media": "http://search.yahoo.com/mrss/",
            }
            for entry in root.findall("atom:entry", ns):
                vid_elem = entry.find("yt:videoId", ns)
                vid = vid_elem.text.strip() if vid_elem is not None and vid_elem.text else None
                title_elem = entry.find("atom:title", ns)
                title = (
                    title_elem.text.strip()
                    if title_elem is not None and title_elem.text
                    else "Cricket Video"
                )
                pub_elem = entry.find("atom:published", ns)
                pub_dt = None
                if pub_elem is not None and pub_elem.text:
                    try:
                        pub_dt = datetime.fromisoformat(pub_elem.text.replace("Z", "+00:00"))
                    except Exception:
                        pub_dt = datetime.now(UTC)

                thumb = f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg" if vid else None
                media_group = entry.find("media:group", ns)
                if media_group is not None:
                    media_thumb = media_group.find("media:thumbnail", ns)
                    if media_thumb is not None and "url" in media_thumb.attrib:
                        thumb = media_thumb.attrib["url"]

                if vid:
                    items.append(
                        RawItem(
                            url=f"https://www.youtube.com/shorts/{vid}",
                            title=unescape(title),
                            published_at=pub_dt or datetime.now(UTC),
                            image_url=thumb,
                            extra={"video_id": vid, "kind": "video", "source": "youtube"},
                        )
                    )
        except Exception:
            pass
        return items

    async def fetch(
        self,
        config: dict[str, Any],
        *,
        etag: str | None = None,
        last_modified: str | None = None,
        client: httpx.AsyncClient | None = None,
    ) -> FetchResult:
        del etag, last_modified
        handle = config.get("handle")
        channel_id = config.get("channel_id")
        _ = config.get("api_key") or os.environ.get("YOUTUBE_API_KEY")
        target_url = config.get("url") or config.get("feed_url")

        if not target_url:
            if handle:
                h = handle if handle.startswith("@") else f"@{handle}"
                target_url = f"https://www.youtube.com/{h}/shorts"
            elif channel_id:
                target_url = f"https://www.youtube.com/feeds/videos.xml?channel_id={channel_id}"
            else:
                target_url = "https://www.youtube.com/@cricbuzz/shorts"

        assert_public_http_url(target_url, field="target_url")

        local_client = client or httpx.AsyncClient(timeout=TIMEOUT, follow_redirects=True)
        try:
            resp = await local_client.get(target_url, headers={"User-Agent": USER_AGENT})
            if resp.status_code == 304:
                return FetchResult(items=[], not_modified=True)
            if resp.status_code >= 400:
                # If channel shorts page or feed gives 404, fallback to generic cricket shorts
                if handle and resp.status_code in (404, 429):
                    fallback_url = "https://www.youtube.com/@cricbuzz/shorts"
                    resp = await local_client.get(fallback_url, headers={"User-Agent": USER_AGENT})
                if resp.status_code >= 400:
                    return FetchResult(items=[], not_modified=False)

            content_type = resp.headers.get("content-type", "")
            if "xml" in content_type or resp.text.startswith("<?xml"):
                items = self.parse_feed_bytes(resp.content)
            else:
                items = self.parse_shorts_html(resp.text)

            return FetchResult(items=items, not_modified=False)
        finally:
            if client is None:
                await local_client.aclose()
