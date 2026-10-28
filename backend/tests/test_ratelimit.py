import pytest

from app.core.errors import RateLimited
from app.core.ratelimit import RateLimiter


@pytest.mark.asyncio
async def test_allows_up_to_the_limit_then_blocks() -> None:
    limiter = RateLimiter()
    for _ in range(3):
        await limiter.hit("login:1.1.1.1", limit=3, window_s=60)
    with pytest.raises(RateLimited):
        await limiter.hit("login:1.1.1.1", limit=3, window_s=60)


@pytest.mark.asyncio
async def test_keys_are_independent() -> None:
    limiter = RateLimiter()
    await limiter.hit("a", limit=1, window_s=60)
    await limiter.hit("b", limit=1, window_s=60)
    with pytest.raises(RateLimited):
        await limiter.hit("a", limit=1, window_s=60)
