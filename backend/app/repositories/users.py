from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User


async def get_by_firebase_uid(session: AsyncSession, firebase_uid: str) -> User | None:
    return await session.scalar(select(User).where(User.firebase_uid == firebase_uid))


async def get_by_id(session: AsyncSession, user_id: object) -> User | None:
    return await session.get(User, user_id)


async def upsert_local(
    session: AsyncSession, *, firebase_uid: str, phone: str, name: str | None = None
) -> User:
    existing = await get_by_firebase_uid(session, firebase_uid)
    if existing is not None:
        if existing.deleted_at is not None:
            existing.deleted_at = None
        return existing
    user = User(firebase_uid=firebase_uid, phone=phone, name=name)
    session.add(user)
    await session.flush()
    return user
