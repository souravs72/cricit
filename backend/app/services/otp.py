from __future__ import annotations

import contextlib
import secrets
import time

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import AppError
from app.core.redis import get_redis
from app.repositories import users as users_repo
from app.schemas.auth import SendOtpOut, TokenPair
from app.services import tokens as token_service

_MEMORY_OTP: dict[str, tuple[str, float]] = {}


async def send_otp(phone: str, channel: str = "ntfy") -> SendOtpOut:
    """Generates a dynamic 6-digit OTP and dispatches it via ntfy.sh for free."""
    # Generate random 6-digit OTP
    code = f"{secrets.randbelow(900000) + 100000}"
    expires_at = time.time() + 300
    _MEMORY_OTP[phone] = (code, expires_at)

    redis = get_redis()
    if redis is not None:
        with contextlib.suppress(Exception):
            await redis.set(f"otp:{phone}", code, ex=300)

    topic = f"cricit-otp-{phone}"
    channel_url = f"https://ntfy.sh/{topic}"
    message = (
        f"Your CRICIT verification code is: {code}\n\n"
        "Enter this in the app to log in. Valid for 5 minutes."
    )

    with contextlib.suppress(Exception):
        async with httpx.AsyncClient(timeout=6.0) as client:
            await client.post(
                channel_url,
                headers={
                    "Title": "CRICIT Verification Code",
                    "Priority": "high",
                    "Tags": "cricket,lock,key",
                },
                content=message,
            )

    return SendOtpOut(
        success=True,
        phone=phone,
        channel=channel,
        channel_url=channel_url,
        expires_in=300,
        message=f"Real OTP sent to notification stream: {channel_url}",
    )


async def verify_otp(
    db: AsyncSession,
    settings: Settings,
    *,
    phone: str,
    code: str,
    device_id: str | None = None,
) -> TokenPair:
    """Validates the dynamic OTP and issues session token pair."""
    stored_code: str | None = None
    redis = get_redis()
    if redis is not None:
        with contextlib.suppress(Exception):
            raw = await redis.get(f"otp:{phone}")
            if raw:
                stored_code = raw.decode("utf-8") if isinstance(raw, bytes) else str(raw)

    if stored_code is None and phone in _MEMORY_OTP:
        c, exp = _MEMORY_OTP[phone]
        if time.time() <= exp:
            stored_code = c

    # Allow 123456 bypass only in non-production environments
    is_valid = (stored_code is not None and code == stored_code) or (
        settings.env not in {"staging", "production"} and code == "123456"
    )

    if not is_valid:
        raise AppError("Invalid or expired OTP", field="code")

    # Invalidate used OTP
    _MEMORY_OTP.pop(phone, None)
    if redis is not None:
        with contextlib.suppress(Exception):
            await redis.delete(f"otp:{phone}")

    uid = f"phone:{phone}"
    user = await users_repo.upsert_local(db, firebase_uid=uid, phone=phone)
    pair = await token_service.open_session(
        db,
        settings,
        typ="user",
        principal_id=str(user.id),
        device_id=device_id or "cricit-web",
    )
    await db.commit()
    return pair
