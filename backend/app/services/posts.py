"""Editorial writes on cards: publish and reject (T19). Audited.

Callers: app.api.admin.routes POST /admin/v1/posts/{id}/publish and /reject.
API: those two endpoints. Schema: PostListItem.
User: "Check what is tobe built now into this - build it"
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import Conflict, NotFound
from app.repositories import audit as audit_repo
from app.repositories import posts as posts_repo
from app.schemas.newsroom import PostListItem
from app.services.newsroom import post_item

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
