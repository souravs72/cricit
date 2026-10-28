"""Admin email + password + TOTP. Challenge lives in Redis (or memory in local/test)."""

from __future__ import annotations

import json
import secrets
import time
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import RateLimited, Unauthorized
from app.core.permissions import Role, permissions_for
from app.core.security import tokens_match, verify_password, verify_totp
from app.models import Admin
from app.repositories import admins as admins_repo
from app.repositories import audit as audit_repo
from app.schemas.auth import AdminChallenge, TokenPair
from app.services import tokens as token_service

GENERIC_LOGIN = "Email or password is wrong."
LOCK_AFTER = 5
LOCK_FOR = timedelta(minutes=15)
CHALLENGE_TTL_S = 300

_memory_challenges: dict[str, tuple[float, dict[str, str]]] = {}


def is_locked(admin: Admin, now: datetime) -> bool:
    return admin.locked_until is not None and now < admin.locked_until


def register_failure(admin: Admin, now: datetime) -> None:
    admin.failed_logins += 1
    if admin.failed_logins >= LOCK_AFTER:
        admin.locked_until = now + LOCK_FOR
        admin.failed_logins = 0


def register_success(admin: Admin) -> None:
    admin.failed_logins = 0
    admin.locked_until = None


async def _put_challenge(redis: Redis | None, challenge_id: str, payload: dict[str, str]) -> None:
    raw = json.dumps(payload)
    if redis is not None:
        await redis.setex(f"admin_challenge:{challenge_id}", CHALLENGE_TTL_S, raw)
        return
    _memory_challenges[challenge_id] = (time.time() + CHALLENGE_TTL_S, payload)


async def _pop_challenge(redis: Redis | None, challenge_id: str) -> dict[str, str] | None:
    if redis is not None:
        key = f"admin_challenge:{challenge_id}"
        raw = await redis.get(key)
        if raw is None:
            return None
        await redis.delete(key)
        data: dict[str, Any] = json.loads(raw)
        return {str(k): str(v) for k, v in data.items()}
    packed = _memory_challenges.pop(challenge_id, None)
    if packed is None or packed[0] < time.time():
        return None
    return packed[1]


async def login(
    db: AsyncSession,
    settings: Settings,
    redis: Redis | None,
    *,
    email: str,
    password: str,
    ip: str | None,
) -> AdminChallenge:
    del settings
    now = datetime.now(UTC)
    admin = await admins_repo.get_by_email(db, email)
    if admin is None or not admin.is_active or admin.password_hash is None:
        await audit_repo.write(db, action="admin.login.fail", entity="admin", note="unknown", ip=ip)
        await db.commit()
        raise Unauthorized(GENERIC_LOGIN)
    if is_locked(admin, now):
        raise RateLimited("Too many tries. Wait 15 minutes and try again.")
    if not verify_password(admin.password_hash, password):
        register_failure(admin, now)
        await audit_repo.write(
            db,
            action="admin.login.fail",
            entity="admin",
            entity_id=str(admin.id),
            admin_id=admin.id,
            ip=ip,
        )
        await db.commit()
        raise Unauthorized(GENERIC_LOGIN)
    challenge_id = secrets.token_urlsafe(24)
    await _put_challenge(redis, challenge_id, {"admin_id": str(admin.id), "email": admin.email})
    await audit_repo.write(
        db,
        action="admin.login.challenge",
        entity="admin",
        entity_id=str(admin.id),
        admin_id=admin.id,
        ip=ip,
    )
    await db.commit()
    return AdminChallenge(challenge_id=challenge_id)


async def verify_second_factor(
    db: AsyncSession,
    settings: Settings,
    redis: Redis | None,
    *,
    challenge_id: str,
    code: str,
    ip: str | None,
    user_agent: str | None,
) -> TokenPair:
    payload = await _pop_challenge(redis, challenge_id)
    if payload is None:
        raise Unauthorized("That code expired. Sign in again.")
    admin = await admins_repo.get_by_id(db, UUID(payload["admin_id"]))
    if admin is None or not admin.is_active:
        raise Unauthorized("That code expired. Sign in again.")
    now = datetime.now(UTC)
    ok = False
    if admin.totp_secret and len(code) == 6 and code.isdigit():
        ok = verify_totp(admin.totp_secret, code)
    if not ok:
        for rec in await admins_repo.unused_recovery_hashes(db, admin.id):
            if tokens_match(rec.code_hash, code):
                rec.used_at = now
                ok = True
                break
    if not ok:
        register_failure(admin, now)
        await audit_repo.write(
            db,
            action="admin.totp.fail",
            entity="admin",
            entity_id=str(admin.id),
            admin_id=admin.id,
            ip=ip,
        )
        await db.commit()
        raise Unauthorized("That code is wrong. Try again.")
    register_success(admin)
    perms = tuple(p.value for p in permissions_for(Role(admin.role)))
    pair = await token_service.open_session(
        db,
        settings,
        typ="admin",
        principal_id=str(admin.id),
        permissions=perms,
        user_agent=user_agent,
    )
    await audit_repo.write(
        db,
        action="admin.login.ok",
        entity="admin",
        entity_id=str(admin.id),
        admin_id=admin.id,
        ip=ip,
    )
    await db.commit()
    return pair
