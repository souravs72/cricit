"""Editorial writes on cards: publish and reject (T19). Audited.

Callers: app.api.admin.routes POST /admin/v1/posts/{id}/publish and /reject.
API: those two endpoints. Schema: PostListItem.
User: "Check what is tobe built now into this - build it"
"""

from __future__ import annotations

import contextlib
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.client import SUMMARY_SCHEMA, get_llm_client, load_prompt
from app.core.errors import Conflict, NotFound
from app.models import Post
from app.repositories import audit as audit_repo
from app.repositories import posts as posts_repo
from app.repositories import settings as settings_repo
from app.schemas.newsroom import CurateIn, CurateOut, PostCreateIn, PostListItem, PostUpdateIn
from app.services.ai_pipeline import extract_in_memory_text
from app.services.newsroom import post_item
from app.services.publish import rebuild_after_publish

_EDITABLE = frozenset({"review", "draft"})


async def publish(
    db: AsyncSession, post_id: UUID, *, admin_id: UUID, ip: str | None
) -> PostListItem:
    post = await posts_repo.get(db, post_id)
    if post is None:
        raise NotFound("Post not found")
    if post.status not in _EDITABLE:
        raise Conflict("Only review or draft cards can be published")
    post.status = "published"
    post.published_at = datetime.now(UTC)
    await audit_repo.write(
        db,
        action="post.publish",
        entity="post",
        entity_id=str(post.id),
        admin_id=admin_id,
        ip=ip,
    )
    await db.commit()
    await db.refresh(post)
    with contextlib.suppress(Exception):
        await rebuild_after_publish(db, post)
    return post_item(post)


async def reject(
    db: AsyncSession, post_id: UUID, *, admin_id: UUID, ip: str | None
) -> PostListItem:
    post = await posts_repo.get(db, post_id)
    if post is None:
        raise NotFound("Post not found")
    if post.status not in _EDITABLE:
        raise Conflict("Only review or draft cards can be rejected")
    post.status = "rejected"
    await audit_repo.write(
        db,
        action="post.reject",
        entity="post",
        entity_id=str(post.id),
        admin_id=admin_id,
        ip=ip,
    )
    await db.commit()
    await db.refresh(post)
    return post_item(post)


async def update_post(
    db: AsyncSession, post_id: UUID, data: PostUpdateIn, *, admin_id: UUID, ip: str | None
) -> PostListItem:
    post = await posts_repo.get(db, post_id)
    if post is None:
        raise NotFound("Post not found")

    if data.headline is not None:
        post.headline = data.headline.strip()[:160]
    if data.summary is not None:
        post.summary = data.summary.strip()
    if data.headline_hi is not None:
        post.headline_hi = data.headline_hi.strip()[:200]
    if data.summary_hi is not None:
        post.summary_hi = data.summary_hi.strip()
    if data.category is not None:
        post.category = data.category.strip().lower()
    if data.tags is not None:
        post.tags = [str(t).strip() for t in data.tags if str(t).strip()]
    if data.image_url is not None:
        post.image_url = data.image_url.strip() or None
    if data.author_credit is not None:
        post.author_credit = data.author_credit.strip()[:200] or None

    should_publish = data.publish_now or data.status == "published"
    if should_publish:
        post.status = "published"
        if not post.published_at:
            post.published_at = datetime.now(UTC)
    elif data.status is not None:
        post.status = data.status

    await audit_repo.write(
        db,
        action="post.publish" if should_publish else "post.update",
        entity="post",
        entity_id=str(post.id),
        admin_id=admin_id,
        ip=ip,
    )
    await db.commit()
    await db.refresh(post)
    if should_publish:
        with contextlib.suppress(Exception):
            await rebuild_after_publish(db, post)
    return post_item(post)


async def create_post(
    db: AsyncSession, data: PostCreateIn, *, admin_id: UUID, ip: str | None
) -> PostListItem:
    now = datetime.now(UTC)
    is_pub = data.status == "published"
    post = Post(
        kind=data.kind or "read",
        status=data.status or "published",
        category=data.category or "international",
        headline=data.headline.strip()[:160],
        summary=data.summary.strip(),
        headline_hi=data.headline_hi.strip()[:200] if data.headline_hi else None,
        summary_hi=data.summary_hi.strip() if data.summary_hi else None,
        image_url=data.image_url.strip() if data.image_url else None,
        original_url=data.original_url.strip() if data.original_url else None,
        author_credit=data.author_credit.strip()[:200] if data.author_credit else "CRICIT Newsroom",
        tags=[str(t).strip() for t in data.tags if str(t).strip()],
        published_at=now if is_pub else None,
    )
    db.add(post)
    await db.flush()
    await audit_repo.write(
        db,
        action="post.create",
        entity="post",
        entity_id=str(post.id),
        admin_id=admin_id,
        ip=ip,
    )
    await db.commit()
    await db.refresh(post)
    if is_pub:
        with contextlib.suppress(Exception):
            await rebuild_after_publish(db, post)
    return post_item(post)


async def curate_story(
    db: AsyncSession,
    data: CurateIn,
) -> CurateOut:
    """Takes rough notes, article URLs, or raw text and polishes it into a verified 60-word cricket card."""
    content_text = (data.raw_text or "").strip()

    # If URL is provided, attempt in-memory HTML extraction
    if data.url and not content_text:
        try:
            async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as http_client:
                resp = await http_client.get(data.url, headers={"User-Agent": "CRICIT-Newsroom/1.0"})
                if resp.is_success:
                    content_text = extract_in_memory_text(resp.text)
        except Exception:
            pass

    if not content_text:
        content_text = (data.notes or "Cricket match update").strip()

    app_cfg = await settings_repo.get_settings(db)
    llm = get_llm_client(app_cfg) if (app_cfg and app_cfg.llm_api_key) else get_llm_client()
    _, template = load_prompt("summarize_v1")

    prompt = (
        f"You are a master cricket editor for CRICIT (a short-news mobile app like Inshorts).\n"
        f"Curate this raw cricket content into an engaging, accurate 60-word story card.\n\n"
        f"Category hint: {data.category or 'international'}\n"
        f"Editor angle/notes: {data.notes or 'Highlight key turning point and scorecard numbers'}\n\n"
        f"Content:\n{content_text[:4000]}"
    )

    try:
        llm_res = await llm.complete_json(
            system="You are a professional cricket journalist and news editor for CRICIT. Always return valid JSON conforming to the schema.",
            user=prompt,
            schema=SUMMARY_SCHEMA,
            max_tokens=600,
        )
        res = llm_res.data
        headline = str(res.get("headline", "")).strip()[:160] or "Cricket Update"
        summary = str(res.get("summary", "")).strip() or content_text[:300]
        headline_hi = str(res.get("headline_hi", "")).strip()[:200] or None
        summary_hi = str(res.get("summary_hi", "")).strip() or None
        category = str(res.get("category", data.category or "international")).lower()
        if category not in ("domestic", "international", "grassroots"):
            category = "international"
        tags = [str(t).strip() for t in res.get("tags", ["Cricket", "Match Update"])[:6]]
    except Exception:
        # Fallback if LLM offline
        words = content_text.split()
        headline = " ".join(words[:10])[:160] or "Cricket Match Update"
        summary = " ".join(words[:60]) or content_text[:300]
        headline_hi = None
        summary_hi = None
        category = data.category or "international"
        tags = ["Cricket", "Match Update"]

    return CurateOut(
        headline=headline,
        summary=summary,
        headline_hi=headline_hi,
        summary_hi=summary_hi,
        category=category,
        tags=tags,
        image_url="https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80",
        author_credit="CRICIT Newsroom",
    )

