"""Database access for the AI-generated Daily Over question bank."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import date
from typing import Any

from sqlalchemy import delete, func, select, text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession

from app.models.trivia import DailyTriviaQuestion

BALLS_PER_OVER = 6
# Arbitrary constant naming the "one trivia generator at a time" Postgres advisory lock.
GENERATOR_LOCK_KEY = 0x0C41C17_7A1A


@dataclass(frozen=True)
class StoredQuestion:
    question: str
    options: tuple[str, ...]
    correct_index: int


async def filled_days(db: AsyncSession, days: list[date]) -> set[date]:
    """Days that already have a complete over."""
    stmt = (
        select(DailyTriviaQuestion.puzzle_date)
        .where(DailyTriviaQuestion.puzzle_date.in_(days))
        .group_by(DailyTriviaQuestion.puzzle_date)
        .having(func.count() >= BALLS_PER_OVER)
    )
    return set((await db.execute(stmt)).scalars().all())


async def all_questions(db: AsyncSession) -> list[StoredQuestion]:
    """Every question ever stored, newest first."""
    stmt = select(
        DailyTriviaQuestion.question,
        DailyTriviaQuestion.options,
        DailyTriviaQuestion.correct_index,
    ).order_by(DailyTriviaQuestion.puzzle_date.desc(), DailyTriviaQuestion.ball_number)
    return [
        StoredQuestion(question=q, options=tuple(o), correct_index=c)
        for q, o, c in (await db.execute(stmt)).all()
    ]


async def delete_incomplete_day(db: AsyncSession, day: date) -> None:
    """Removes a half-written over so the day can be generated cleanly.

    Only called for days without a complete over; such a day was never served or played.
    """
    count = await db.scalar(select(func.count()).where(DailyTriviaQuestion.puzzle_date == day))
    if count and count < BALLS_PER_OVER:
        await db.execute(delete(DailyTriviaQuestion).where(DailyTriviaQuestion.puzzle_date == day))
        await db.commit()


async def insert_over(db: AsyncSession, day: date, balls: list[dict[str, Any]]) -> None:
    """Stores six questions for `day` in one transaction (caller commits)."""
    db.add_all(DailyTriviaQuestion(puzzle_date=day, **ball) for ball in balls)


@asynccontextmanager
async def generator_lock(engine: AsyncEngine) -> AsyncIterator[bool]:
    """Yields True when this process holds the bank-generation lock, False if another does.

    A session-level advisory lock on a dedicated connection, so two worker runs can never
    generate at the same time and slip similar questions past each other's checks.
    """
    async with engine.connect() as conn:
        acquired = bool(
            await conn.scalar(text("SELECT pg_try_advisory_lock(:k)"), {"k": GENERATOR_LOCK_KEY})
        )
        try:
            yield acquired
        finally:
            if acquired:
                await conn.execute(text("SELECT pg_advisory_unlock(:k)"), {"k": GENERATOR_LOCK_KEY})
            await conn.commit()
