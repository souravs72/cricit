"""Turn a fetched RSS page into posts. Never stores article bodies (T10, T12).

Callers: workers.fetch_source (app/workers/main.py), tests/test_ingest.py.
API: none directly; worker job fetch_source writes posts.
Schemas: PlannedPost, Post (headline, summary teaser, original_url, url_hash, status).
"""

from __future__ import annotations

import contextlib
import re
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from html import unescape
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.ingestion.adapters import FETCHABLE, adapter_for
from app.ingestion.adapters.base import FetchResult, RawItem
from app.ingestion.adapters.rss import RssAdapter
from app.ingestion.dedupe import Candidate, Verdict, check_pass1, url_hash
from app.models import Post, Source
from app.repositories import posts as posts_repo
from app.repositories import sources as sources_repo

FAIL_PAUSE_AFTER = 5
TEASER_WORDS = 60
_TAGS = re.compile(r"<[^>]+>")
_WS = re.compile(r"\s+")


def rss_teaser(raw: str | None) -> str:
    text = _WS.sub(" ", unescape(_TAGS.sub(" ", raw or ""))).strip()
    return " ".join(text.split()[:TEASER_WORDS])


def job_id_for(source_id: UUID, interval_min: int, *, at: datetime | None = None) -> str:
    now = at or datetime.now(UTC)
    slot = int(now.timestamp()) // max(int(interval_min) * 60, 1)
    return f"fetch:{source_id}:{slot}"


def is_due(source: Source, *, now: datetime | None = None) -> bool:
    if not source.is_active or source.adapter not in FETCHABLE:
        return False
    clock = now or datetime.now(UTC)
    if source.last_fetched_at is None:
        return True
    last = source.last_fetched_at
    if last.tzinfo is None:
        last = last.replace(tzinfo=UTC)
    return clock - last >= timedelta(minutes=source.fetch_interval_min)


def record_failure(source: Source, message: str) -> None:
    source.consecutive_failures = int(source.consecutive_failures or 0) + 1
    source.last_error = (message or "fetch failed")[:500]
    if source.consecutive_failures >= FAIL_PAUSE_AFTER:
        source.is_active = False


def record_success(
    source: Source,
    *,
    etag: str | None,
    last_modified: str | None,
    now: datetime,
) -> None:
    source.consecutive_failures = 0
    source.last_error = None
    source.last_fetched_at = now
    cfg = dict(source.adapter_config or {})
    if etag:
        cfg["etag"] = etag
    if last_modified:
        cfg["last_modified"] = last_modified
    source.adapter_config = cfg


def fetch_result_from_bytes(
    content: bytes, *, status_code: int = 200, etag: str | None = None
) -> FetchResult:
    if status_code == 304:
        return FetchResult(items=[], etag=etag, not_modified=True)
    return FetchResult(items=RssAdapter.parse_bytes(content), etag=etag, not_modified=False)


def _match(new: Candidate, recent: list[tuple[UUID, Candidate]]) -> tuple[Verdict, UUID | None]:
    rank = {Verdict.DISTINCT: 0, Verdict.POSSIBLE: 1, Verdict.DUPLICATE: 2}
    best = Verdict.DISTINCT
    best_id: UUID | None = None
    for pid, old in recent:
        verdict = check_pass1(new, [old])
        if rank[verdict] > rank[best]:
            best, best_id = verdict, pid
    return best, best_id


@dataclass(frozen=True)
class PlannedPost:
    headline: str
    summary: str
    original_url: str
    url_hash: str
    status: str
    published_at: datetime | None
    merge_into: UUID | None
    possible_duplicate_of: UUID | None
    image_url: str | None


def plan_items(
    source: Source,
    items: list[RawItem],
    *,
    known_hashes: set[str],
    recent: list[tuple[UUID, Candidate]],
    now: datetime,
) -> list[PlannedPost]:
    planned: list[PlannedPost] = []
    seen = set(known_hashes)
    for item in items:
        digest = url_hash(item.url)
        if digest in seen:
            continue
        seen.add(digest)
        published = item.published_at or now
        if published.tzinfo is None:
            published = published.replace(tzinfo=UTC)
        verdict, match_id = _match(Candidate(item.title, published), recent)
        if verdict is Verdict.DUPLICATE and match_id is not None:
            planned.append(
                PlannedPost(
                    headline=item.title[:160],
                    summary=rss_teaser(str(item.extra.get("summary") or item.title)),
                    original_url=item.url,
                    url_hash=digest,
                    status="review",
                    published_at=None,
                    merge_into=match_id,
                    possible_duplicate_of=match_id,
                    image_url=item.image_url,
                )
            )
            continue
        needs_review = source.trust_level == "review" or verdict is Verdict.POSSIBLE
        status = "review" if needs_review else "published"
        planned.append(
            PlannedPost(
                headline=item.title[:160],
                summary=rss_teaser(str(item.extra.get("summary") or item.title)),
                original_url=item.url,
                url_hash=digest,
                status=status,
                published_at=published if status == "published" else None,
                merge_into=None,
                possible_duplicate_of=match_id if verdict is Verdict.POSSIBLE else None,
                image_url=item.image_url,
            )
        )
    return planned


async def fetch_and_store(db: AsyncSession, source_id: UUID) -> dict[str, int | str | bool]:
    source = await sources_repo.get(db, source_id)
    adapter = adapter_for(source.adapter) if source is not None else None
    if source is None or adapter is None:
        return {"skipped": True, "created": 0, "merged": 0}
    now = datetime.now(UTC)
    cfg = dict(source.adapter_config or {})
    etag = cfg.get("etag")
    last_modified = cfg.get("last_modified")
    try:
        result = await adapter.fetch(
            cfg,
            etag=etag if isinstance(etag, str) else None,
            last_modified=last_modified if isinstance(last_modified, str) else None,
        )
    except Exception:
        # Do not store exception text: httpx includes the target URL.
        record_failure(source, "fetch failed")
        await db.commit()
        return {"failed": True, "created": 0, "merged": 0, "error": "fetch failed"}
    if result.not_modified:
        record_success(source, etag=result.etag, last_modified=result.last_modified, now=now)
        await db.commit()
        return {"not_modified": True, "created": 0, "merged": 0}

    hashes = [url_hash(item.url) for item in result.items]
    known = await posts_repo.hashes_in(db, hashes)
    recent_rows = await posts_repo.list_recent_for_dedupe(db)
    recent = [
        (row.id, Candidate(row.headline, row.published_at or row.created_at or now))
        for row in recent_rows
    ]
    created = 0
    merged = 0
    for plan in plan_items(source, result.items, known_hashes=known, recent=recent, now=now):
        if plan.merge_into is not None:
            await posts_repo.add_source_link(
                db, post_id=plan.merge_into, source_id=source.id, url=plan.original_url
            )
            merged += 1
            continue
        db.add(
            Post(
                kind="read",
                status=plan.status,
                category=source.default_category,
                headline=plan.headline,
                summary=plan.summary,
                original_url=plan.original_url,
                url_hash=plan.url_hash,
                source_id=source.id,
                possible_duplicate_of=plan.possible_duplicate_of,
                author_credit=source.name,
                image_url=plan.image_url,
                tags=[],
                published_at=plan.published_at,
            )
        )
        created += 1
    record_success(source, etag=result.etag, last_modified=result.last_modified, now=now)
    await db.commit()
    if created:
        from app.services.publish import invalidate_all_feeds

        with contextlib.suppress(Exception):
            await invalidate_all_feeds()
    return {"created": created, "merged": merged, "not_modified": False}
