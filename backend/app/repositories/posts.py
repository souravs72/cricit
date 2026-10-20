"""All SQL for posts lives here."""

import uuid
from datetime import datetime

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Post


async def list_published(
    session: AsyncSession,
    *,
    category: str | None,
    kind: str | None,
    after: tuple[datetime, uuid.UUID] | None,
    limit: int,
) -> list[Post]:
    """Newest first, keyset-paginated on (published_at, id) so inserts never shift pages."""
    stmt = select(Post).where(Post.status == "published")
    if category:
        stmt = stmt.where(Post.category == category)
    if kind:
        stmt = stmt.where(Post.kind == kind)
    if after:
        ts, pid = after
        stmt = stmt.where(or_(Post.published_at < ts, and_(Post.published_at == ts, Post.id < pid)))
    stmt = stmt.order_by(Post.published_at.desc(), Post.id.desc()).limit(limit)
    return list((await session.scalars(stmt)).all())
