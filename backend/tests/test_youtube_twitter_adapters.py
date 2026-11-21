"""Test YouTube and Twitter/X adapters (T17, News & Social triggers)."""

import pytest

from app.ingestion.adapters import FETCHABLE, adapter_for
from app.ingestion.adapters.twitter import TwitterAdapter
from app.ingestion.adapters.youtube import YoutubeAdapter


def test_youtube_adapter_registered() -> None:
    assert "youtube" in FETCHABLE
    assert "twitter" in FETCHABLE
    assert "x" in FETCHABLE
    assert isinstance(adapter_for("youtube"), YoutubeAdapter)
    assert isinstance(adapter_for("twitter"), TwitterAdapter)
    assert isinstance(adapter_for("x"), TwitterAdapter)


def test_youtube_html_parser() -> None:
    html = """
    <div>Sample text</div>
    <script>var ytInitialData = {"contents":{"twoColumnBrowseResultsRenderer":{"tabs":[{"tabRenderer":{"selected":true,"content":{"richGridRenderer":{"contents":[{"richItemRenderer":{"content":{"shortsLockupViewModel":{"entityId":"shorts-shelf-item-xtn0lf5TY84","overlayMetadata":{"primaryText":{"content":"Bumrah Yorker in Perth #Shorts"}}}}}}]}}}}]}}};</script>
    """
    items = YoutubeAdapter.parse_shorts_html(html)
    assert len(items) == 1
    assert items[0].extra["video_id"] == "xtn0lf5TY84"
    assert "Bumrah Yorker" in items[0].title
    assert items[0].extra["kind"] == "video"
    assert items[0].image_url == "https://i.ytimg.com/vi/xtn0lf5TY84/hqdefault.jpg"


def test_youtube_feed_parser() -> None:
    atom_xml = b"""<?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:yt="http://www.youtube.com/xml/schemas/2015">
      <entry>
        <yt:videoId>zkXTEiNYtm8</yt:videoId>
        <title>Virat Kohli Net Session Ahead of 1st Test</title>
        <published>2026-11-06T12:00:00+00:00</published>
      </entry>
    </feed>
    """
    items = YoutubeAdapter.parse_feed_bytes(atom_xml)
    assert len(items) == 1
    assert items[0].extra["video_id"] == "zkXTEiNYtm8"
    assert "Virat Kohli" in items[0].title


def test_twitter_api_v2_parser() -> None:
    payload = {
        "data": [
            {
                "id": "1853729104819200001",
                "text": "Squad announcement: Team India for Border-Gavaskar Trophy https://t.co/xyz",
                "attachments": {"media_keys": ["3_1853729104819200002"]},
            }
        ],
        "includes": {
            "media": [
                {
                    "media_key": "3_1853729104819200002",
                    "preview_image_url": "https://pbs.twimg.com/media/preview.jpg",
                }
            ]
        },
    }
    items = TwitterAdapter.parse_api_v2(payload, "BCCI")
    assert len(items) == 1
    assert items[0].extra["tweet_id"] == "1853729104819200001"
    assert "Squad announcement" in items[0].title
    assert items[0].image_url == "https://pbs.twimg.com/media/preview.jpg"


@pytest.mark.asyncio
async def test_twitter_fetch_curated_fallback() -> None:
    adapter = TwitterAdapter()
    result = await adapter.fetch({"handle": "BCCI"})
    assert not result.not_modified
    assert len(result.items) > 0
    assert result.items[0].extra["source"] == "x"
