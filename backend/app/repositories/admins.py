from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Admin, AdminRecoveryCode


async def get_by_email(session: AsyncSession, email: str) -> Admin | None:
    return await session.scalar(select(Admin).where(Admin.email == email.lower()))


async def get_by_id(session: AsyncSession, admin_id: object) -> Admin | None:
    return await session.get(Admin, admin_id)


async def unused_recovery_hashes(
    session: AsyncSession, admin_id: object
) -> list[AdminRecoveryCode]:
    stmt = select(AdminRecoveryCode).where(
        AdminRecoveryCode.admin_id == admin_id,
        AdminRecoveryCode.used_at.is_(None),
    )
    return list((await session.scalars(stmt)).all())
