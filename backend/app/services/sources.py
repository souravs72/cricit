"""CRUD and dry-run fetch for news sources (T09). Every write is audited.

Callers: app.api.admin.routes (POST/PATCH /admin/v1/sources, POST /admin/v1/sources/{id}/test).
API: those three endpoints. Schemas: SourceCreate, SourcePatch, SourceOut, TestFetchOut.
User: "Check what is tobe built now into this - build it"
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import Conflict, NotBuiltYet, NotFound
from app.ingestion.adapters.rss import RssAdapter
from app.ingestion.ssrf import assert_safe_to_fetch
from app.models import Source
from app.repositories import audit as audit_repo
from app.repositories import sources as sources_repo
from app.schemas.newsroom import SourceOut
from app.schemas.sources import (
    SourceCreate,
    SourcePatch,
    TestFetchItem,
    TestFetchOut,
    normalised_config,
)
from app.services.newsroom import source_out


async def create(
    db: AsyncSession,
    body: SourceCreate,
    *,
    admin_id: UUID,
    ip: str | None,
) -> SourceOut:
    if await sources_repo.get_by_name(db, body.name):
        raise Conflict("A source with that name already exists", field="name")
    row = Source(
        name=body.name,
        type=body.type,
        adapter=body.adapter,
        adapter_config=body.adapter_config,
        default_category=body.default_category,
        trust_level=body.trust_level,
        fetch_interval_min=body.fetch_interval_min,
        is_active=body.is_active,
        priority=body.priority,
        verified_at=datetime.now(UTC),
    )
    db.add(row)
    await db.flush()
    await audit_repo.write(
        db,
        action="source.create",
        entity="source",
        entity_id=str(row.id),
        admin_id=admin_id,
        diff={"name": row.name, "adapter": row.adapter},
        ip=ip,
    )
    await db.commit()
    await db.refresh(row)
    return source_out(row)


async def update(
    db: AsyncSession,
    source_id: UUID,
    body: SourcePatch,
    *,
    admin_id: UUID,
    ip: str | None,
) -> SourceOut:
    row = await sources_repo.get(db, source_id)
    if row is None:
        raise NotFound("Source not found")
    data = body.model_dump(exclude_unset=True)
    if "name" in data and data["name"] != row.name:
        existing = await sources_repo.get_by_name(db, data["name"])
        if existing is not None and existing.id != row.id:
            raise Conflict("A source with that name already exists", field="name")
    if "adapter" in data and "adapter_config" not in data:
        data["adapter_config"] = normalised_config(data["adapter"], dict(row.adapter_config or {}))
    diff: dict[str, Any] = {}
    for key, value in data.items():
        if getattr(row, key) != value:
            diff[key] = value
            setattr(row, key, value)
    await audit_repo.write(
        db,
        action="source.update",
        entity="source",
        entity_id=str(row.id),
        admin_id=admin_id,
        diff=diff,
        ip=ip,
        note="paused" if data.get("is_active") is False else None,
    )
    await db.commit()
    await db.refresh(row)
    return source_out(row)


async def test_fetch(db: AsyncSession, source_id: UUID) -> TestFetchOut:
    row = await sources_repo.get(db, source_id)
    if row is None:
        raise NotFound("Source not found")
    if row.adapter != "rss":
        raise NotBuiltYet("Test fetch for this adapter is T11 or T17")
    cfg = dict(row.adapter_config or {})
    feed_url = cfg.get("feed_url")
    if not isinstance(feed_url, str):
        raise NotFound("This source has no feed URL")
    assert_safe_to_fetch(feed_url, field="feed_url")
    result = await RssAdapter().fetch(cfg, etag=None, last_modified=None)
    items = [
        TestFetchItem(url=item.url, title=item.title, published_at=item.published_at)
        for item in result.items[:10]
    ]
    return TestFetchOut(not_modified=result.not_modified, item_count=len(result.items), items=items)
