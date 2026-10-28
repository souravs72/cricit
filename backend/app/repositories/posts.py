"""All SQL for posts lives here."""

import uuid
from datetime import datetime

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Post


async def list_by_status(
    session: AsyncSession,
    *,
    status: str,
    limit: int = 50,
) -> list[Post]:
    stmt = select(Post).where(Post.status == status).order_by(Post.updated_at.desc()).limit(limit)
    return list((await session.scalars(stmt)).all())


async def list_all(session: AsyncSession, *, limit: int = 80) -> list[Post]:
    stmt = select(Post).order_by(Post.updated_at.desc()).limit(limit)
    return list((await session.scalars(stmt)).all())


async def search_published(session: AsyncSession, query: str, *, limit: int = 20) -> list[Post]:
    q = f"%{query.strip()}%"
    stmt = (
        select(Post)
        .where(
            Post.status == "published",
            or_(
                Post.headline.ilike(q),
                Post.summary.ilike(q),
                Post.headline_hi.ilike(q),
            ),
        )
        .order_by(Post.published_at.desc())
        .limit(limit)
    )
    return list((await session.scalars(stmt)).all())


async def get(session: AsyncSession, post_id: uuid.UUID) -> Post | None:
    return await session.get(Post, post_id)


async def count_status(session: AsyncSession, status: str) -> int:
    return int(
        await session.scalar(select(func.count()).select_from(Post).where(Post.status == status))
        or 0
    )


async def count_published_since(session: AsyncSession, since: datetime) -> int:
    return int(
        await session.scalar(
            select(func.count())
            .select_from(Post)
            .where(Post.status == "published", Post.published_at >= since)
        )
        or 0
    )


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
