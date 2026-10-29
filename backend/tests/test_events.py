"""T26: /v1/events Redis counters and idempotent hourly rollup.

Callers: pytest (`make check-backend`). API: POST /v1/events.
Schema: EventsIn, EventIn. Never stores raw event rows.
User: "audit the changes and implement more features and build the changes"
"""

from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from app.schemas.events import EventIn, EventsIn
from app.services.events import DIRTY, counter_key, record, rollup
from app.services.feed import FakeRedis

NOW = datetime(2026, 10, 29, 12, tzinfo=UTC)


def test_counter_key_for_post_view_and_skips_incomplete() -> None:
    pid = uuid4()
    key = counter_key(EventIn(name="view", post_id=pid), now=NOW)
    assert key == f"ev:p:{pid}:2026-10-29:views"
    assert counter_key(EventIn(name="view"), now=NOW) is None
    assert counter_key(EventIn(name="ad_impression"), now=NOW) is None
    cid = uuid4()
    ad = counter_key(EventIn(name="ad_click", campaign_id=cid), now=NOW)
    assert ad == f"ev:a:{cid}:2026-10-29:clicks"


def test_far_future_occurred_at_uses_server_day() -> None:
    pid = uuid4()
    future = NOW + timedelta(days=30)
    key = counter_key(EventIn(name="view", post_id=pid, occurred_at=future), now=NOW)
    assert key == f"ev:p:{pid}:2026-10-29:views"


def test_batch_rejects_more_than_100_events() -> None:
    pid = uuid4()
    with pytest.raises(ValidationError):
        EventsIn(
            device_id="device-01",
            events=[EventIn(name="view", post_id=pid) for _ in range(101)],
        )


@pytest.mark.asyncio
async def test_record_increments_redis_counters() -> None:
    redis = FakeRedis()
    pid = uuid4()
    n = await record(
        redis,
        [EventIn(name="view", post_id=pid), EventIn(name="view", post_id=pid)],
        now=NOW,
    )
    assert n == 2
    key = f"ev:p:{pid}:2026-10-29:views"
    assert await redis.get(key) == "2"
    assert key in await redis.smembers(DIRTY)


class _Session:
    @asynccontextmanager
    async def begin_nested(self) -> object:
        yield None

    async def commit(self) -> None:
        return None


@pytest.mark.asyncio
async def test_rollup_is_idempotent(monkeypatch: pytest.MonkeyPatch) -> None:
    redis = FakeRedis()
    pid = uuid4()
    added: list[dict[str, object]] = []

    async def fake_add(session: object, post_id: object, day: object, **kw: int) -> None:
        del session, post_id, day
        added.append(dict(kw))

    monkeypatch.setattr("app.services.events.posts_repo.add_daily_stats", fake_add)

    await record(redis, [EventIn(name="view", post_id=pid)] * 3, now=NOW)
    session = _Session()
    first = await rollup(session, redis)  # type: ignore[arg-type]
    second = await rollup(session, redis)  # type: ignore[arg-type]
    assert first == 1
    assert second == 0
    assert added == [{"views": 3}]
    assert not await redis.smembers(DIRTY)


@pytest.mark.asyncio
async def test_rollup_drops_orphan_keys_on_integrity_error(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    redis = FakeRedis()
    pid = uuid4()

    async def fake_add(session: object, post_id: object, day: object, **kw: int) -> None:
        del session, post_id, day, kw
        raise IntegrityError("insert", {}, Exception("fk"))

    monkeypatch.setattr("app.services.events.posts_repo.add_daily_stats", fake_add)
    await record(redis, [EventIn(name="view", post_id=pid)], now=NOW)
    moved = await rollup(_Session(), redis)  # type: ignore[arg-type]
    assert moved == 0
    assert not await redis.smembers(DIRTY)


def test_events_route_accepts_a_batch(monkeypatch: pytest.MonkeyPatch) -> None:
    redis = FakeRedis()
    monkeypatch.setattr("app.api.v1.routes.get_redis", lambda: redis)
    from app.main import create_app

    client = TestClient(create_app())
    pid = str(uuid4())
    r = client.post(
        "/v1/events",
        json={
            "device_id": "device-01",
            "events": [{"name": "view", "post_id": pid}, {"name": "open", "post_id": pid}],
        },
    )
    assert r.status_code == 204
    assert any(k.endswith(":views") for k in redis.kv)
    assert any(k.endswith(":opens") for k in redis.kv)


def test_events_route_rejects_oversized_batch(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("app.api.v1.routes.get_redis", lambda: FakeRedis())
    from app.main import create_app

    client = TestClient(create_app())
    pid = str(uuid4())
    r = client.post(
        "/v1/events",
        json={
            "device_id": "device-01",
            "events": [{"name": "view", "post_id": pid} for _ in range(101)],
        },
    )
    assert r.status_code == 422
