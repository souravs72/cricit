"""Runs against a real, migrated Postgres (CI service or `make up`). Skipped when unreachable."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.config import Settings
from app.models import Post
from app.services.feed import get_feed

pytestmark = pytest.mark.integration
T0 = datetime(2026, 10, 20, 12, tzinfo=UTC)


@pytest.fixture
async def session():
    settings = Settings()
    engine = create_async_engine(settings.database_url)
    try:
        async with engine.connect():
            pass
    except OSError:
        pytest.skip("Postgres not reachable")
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as s:
        await s.execute(delete(Post))
        await s.commit()
        yield s
        await s.execute(delete(Post))
        await s.commit()
    await engine.dispose()


def _post(i: int, minutes: int, category: str = "international") -> Post:
    return Post(
        kind="read",
        status="published",
        category=category,
        headline=f"Story {i}",
        summary="Summary",
        original_url=f"https://example.com/{i}",
        url_hash=f"{i:064d}",
        published_at=T0 + timedelta(minutes=minutes),
    )


async def test_cursor_pages_never_repeat_or_skip_when_posts_arrive(session):
    settings = Settings(feed_page_size=5)
    session.add_all([_post(i, minutes=i) for i in range(12)])
    await session.commit()

    page1 = await get_feed(session, settings, tab="feed", lang="en", cursor=None)
    # New stories land while the user is swiping.
    session.add_all([_post(100 + i, minutes=60 + i) for i in range(3)])
    await session.commit()
    page2 = await get_feed(session, settings, tab="feed", lang="en", cursor=page1.next_cursor)
    page3 = await get_feed(session, settings, tab="feed", lang="en", cursor=page2.next_cursor)

    seen = [c.headline for p in (page1, page2, page3) for c in p.items]  # type: ignore[union-attr]
    assert seen == [f"Story {i}" for i in range(11, -1, -1)]
    assert page3.next_cursor is None


async def test_tab_filters_by_category(session):
    session.add_all([_post(1, 1, "domestic"), _post(2, 2, "international")])
    await session.commit()
    page = await get_feed(session, Settings(), tab="domestic", lang="en", cursor=None)
    assert [c.headline for c in page.items] == ["Story 1"]  # type: ignore[union-attr]
