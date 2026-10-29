"""T10: RSS ingest from a saved fixture, no network.

Callers: pytest. Modules: RssAdapter, app.services.ingest, worker job ids.
User: "Check what is tobe built now into this - build it"
"""

from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import uuid4

import httpx
import pytest

from app.ingestion.adapters.rss import RssAdapter
from app.ingestion.dedupe import Candidate, url_hash
from app.models import Source
from app.services.ingest import (
    FAIL_PAUSE_AFTER,
    fetch_result_from_bytes,
    is_due,
    job_id_for,
    plan_items,
    record_failure,
    record_success,
    rss_teaser,
)

FIXTURE = Path(__file__).parent / "fixtures" / "rss_sample.xml"
NOW = datetime(2026, 10, 20, 12, tzinfo=UTC)


def _source(**kwargs: object) -> Source:
    defaults: dict[str, object] = {
        "name": "ESPNcricinfo",
        "type": "news",
        "adapter": "rss",
        "adapter_config": {
            "kind": "rss",
            "feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml",
        },
        "default_category": "international",
        "trust_level": "auto",
        "is_active": True,
        "fetch_interval_min": 10,
        "consecutive_failures": 0,
    }
    defaults.update(kwargs)
    return Source(**defaults)  # type: ignore[arg-type]


def test_parse_drops_private_and_non_http_item_links() -> None:
    xml = (
        b'<?xml version="1.0"?><rss version="2.0"><channel>'
        b"<item><title>Bad</title><link>javascript:alert(1)</link></item>"
        b"<item><title>Loop</title><link>http://127.0.0.1/x</link></item>"
        b"<item><title>Ok</title><link>https://www.espncricinfo.com/story/ok</link></item>"
        b"</channel></rss>"
    )
    items = RssAdapter.parse_bytes(xml)
    assert [i.title for i in items] == ["Ok"]


def test_parse_fixture_skips_empty_titles_and_strips_html() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    titles = [i.title for i in items]
    assert "Gill 104 keeps India in front at Perth" in titles
    assert "England rest Archer for the Oval ODI" in titles
    assert all(i.title for i in items)
    gill = next(i for i in items if "Gill" in i.title)
    assert gill.extra["summary"]
    assert "<" not in gill.extra["summary"]


def test_url_hash_collapses_tracking_query_before_insert() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    hashes = {url_hash(i.url) for i in items}
    assert len(items) == 3  # empty title dropped
    assert len(hashes) == 2  # gill + utm mirror share a hash
    planned = plan_items(_source(), items, known_hashes=set(), recent=[], now=NOW)
    urls = [p.original_url for p in planned if p.merge_into is None]
    assert len(urls) == 2


def test_known_url_hash_is_skipped() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    gill = next(i for i in items if "Gill" in i.title)
    planned = plan_items(
        _source(),
        items,
        known_hashes={url_hash(gill.url)},
        recent=[],
        now=NOW,
    )
    assert all("Gill" not in p.headline for p in planned)


def test_review_trust_never_auto_publishes() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    planned = plan_items(
        _source(trust_level="review"),
        items,
        known_hashes=set(),
        recent=[],
        now=NOW,
    )
    assert planned
    assert all(p.status == "review" for p in planned)


def test_auto_trust_publishes_distinct_items() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    planned = plan_items(_source(), items, known_hashes=set(), recent=[], now=NOW)
    assert {p.status for p in planned} == {"published"}


def test_near_duplicate_title_goes_to_review() -> None:
    items = RssAdapter.parse_bytes(FIXTURE.read_bytes())
    gill = next(i for i in items if i.title.startswith("Gill 104"))
    existing_id = uuid4()
    planned = plan_items(
        _source(),
        [gill],
        known_hashes=set(),
        recent=[
            (
                existing_id,
                Candidate("Gill 104 keeps India in front at Perth!", NOW - timedelta(hours=1)),
            )
        ],
        now=NOW,
    )
    assert len(planned) == 1
    assert planned[0].merge_into == existing_id


def test_five_failures_pause_the_source() -> None:
    source = _source(consecutive_failures=4)
    record_failure(source, "connection timed out")
    assert source.consecutive_failures == FAIL_PAUSE_AFTER
    assert source.is_active is False
    assert source.last_error == "connection timed out"


def test_success_clears_failures_and_stores_etag() -> None:
    source = _source(consecutive_failures=3, last_error="boom")
    record_success(source, etag='"abc"', last_modified="Tue, 20 Oct 2026", now=NOW)
    assert source.consecutive_failures == 0
    assert source.last_error is None
    assert source.last_fetched_at == NOW
    assert source.adapter_config["etag"] == '"abc"'


def test_304_is_a_no_op() -> None:
    result = fetch_result_from_bytes(b"", status_code=304, etag='"abc"')
    assert result.not_modified is True
    assert result.items == []


def test_job_id_is_stable_inside_an_interval_slot() -> None:
    sid = uuid4()
    a = job_id_for(sid, 10, at=NOW)
    b = job_id_for(sid, 10, at=NOW + timedelta(minutes=4))
    c = job_id_for(sid, 10, at=NOW + timedelta(minutes=10))
    assert a == b
    assert a != c
    assert a.startswith("fetch:")


def test_due_when_never_fetched_or_interval_elapsed() -> None:
    fresh = _source(last_fetched_at=None)
    recent = _source(last_fetched_at=NOW - timedelta(minutes=3))
    stale = _source(last_fetched_at=NOW - timedelta(minutes=11))
    paused = _source(is_active=False, last_fetched_at=None)
    html = _source(adapter="html", last_fetched_at=None)
    assert is_due(fresh, now=NOW)
    assert not is_due(recent, now=NOW)
    assert is_due(stale, now=NOW)
    assert not is_due(paused, now=NOW)
    assert not is_due(html, now=NOW)


@pytest.mark.asyncio
async def test_adapter_honours_etag_without_network() -> None:
    xml = FIXTURE.read_bytes()

    def handler(request: httpx.Request) -> httpx.Response:
        if request.headers.get("If-None-Match") == '"v1"':
            return httpx.Response(304, headers={"ETag": '"v1"'})
        return httpx.Response(200, content=xml, headers={"ETag": '"v1"'})

    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport, follow_redirects=False) as client:
        adapter = RssAdapter()
        first = await adapter.fetch(
            {"feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"},
            etag=None,
            last_modified=None,
            client=client,
        )
        assert first.not_modified is False
        assert len(first.items) >= 2
        second = await adapter.fetch(
            {"feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"},
            etag='"v1"',
            last_modified=None,
            client=client,
        )
        assert second.not_modified is True
        assert second.items == []


def test_teaser_never_keeps_a_full_article() -> None:
    long = " ".join(["word"] * 200)
    out = rss_teaser(f"<p>{long}</p>")
    assert len(out.split()) <= 60
    assert "<p>" not in out
