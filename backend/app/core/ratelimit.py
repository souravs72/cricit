"""Redis sliding-window counter. Callers pass a key they already scoped (ip, email, device)."""

from __future__ import annotations

from dataclasses import dataclass

from redis.asyncio import Redis

from app.core.errors import RateLimited


@dataclass
class MemoryWindow:
    count: int
    ttl_s: int


class RateLimiter:
    """INCR + EXPIRE on Redis. An in-memory map is used only in tests."""

    def __init__(self, redis: Redis | None = None) -> None:
        self._redis = redis
        self._memory: dict[str, MemoryWindow] = {}

    async def hit(self, key: str, *, limit: int, window_s: int) -> None:
        if self._redis is not None:
            count = int(await self._redis.incr(key))
            if count == 1:
                await self._redis.expire(key, window_s)
            if count > limit:
                raise RateLimited("Too many attempts. Try again shortly.")
            return
        bucket = self._memory.get(key)
        if bucket is None:
            self._memory[key] = MemoryWindow(count=1, ttl_s=window_s)
            return
        bucket.count += 1
        if bucket.count > limit:
            raise RateLimited("Too many attempts. Try again shortly.")
