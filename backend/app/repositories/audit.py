from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AuditLog


async def write(
    session: AsyncSession,
    *,
    action: str,
    entity: str,
    entity_id: str | None = None,
    admin_id: UUID | None = None,
    diff: dict[str, Any] | None = None,
    ip: str | None = None,
    note: str | None = None,
) -> None:
    session.add(
        AuditLog(
            admin_id=admin_id,
            action=action,
            entity=entity,
            entity_id=entity_id,
            diff=diff or {},
            ip=ip,
            ts=datetime.now(UTC),
            note=note,
        )
    )


async def list_recent(session: AsyncSession, *, limit: int = 50) -> list[AuditLog]:
    stmt = select(AuditLog).order_by(AuditLog.ts.desc()).limit(limit)
    return list((await session.scalars(stmt)).all())
