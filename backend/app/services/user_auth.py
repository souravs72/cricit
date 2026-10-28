"""App-user sessions. Production still waits on Firebase (T05); local/test issue tokens."""

from __future__ import annotations

import hashlib

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import NotBuiltYet
from app.repositories import users as users_repo
from app.schemas.auth import TokenPair
from app.services import tokens as token_service


def _dev_phone(firebase_uid: str) -> str:
    digits = "".join(c for c in firebase_uid if c.isdigit())[:9].ljust(9, "0")
    return f"9{digits}"


async def exchange_id_token(
    db: AsyncSession,
    settings: Settings,
    *,
    id_token: str,
    device_id: str,
) -> TokenPair:
    if settings.env in {"staging", "production"}:
        raise NotBuiltYet("T05: verify Firebase ID token, upsert user, open session, issue tokens")
    uid = "dev:" + hashlib.sha256(id_token.encode()).hexdigest()[:16]
    user = await users_repo.upsert_local(db, firebase_uid=uid, phone=_dev_phone(uid))
    pair = await token_service.open_session(
        db,
        settings,
        typ="user",
        principal_id=str(user.id),
        device_id=device_id,
    )
    await db.commit()
    return pair
