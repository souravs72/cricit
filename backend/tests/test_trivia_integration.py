"""Daily Over lock-in and scoring against a real, migrated Postgres. Skipped when unreachable.

These cover what mocks cannot: row locking under concurrent requests.
"""

import asyncio
import uuid
from datetime import date
from typing import Any

import pytest
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker, create_async_engine

from app.ai.client import LLMResult
from app.core.config import Settings
from app.models import User
from app.models.trivia import DailyTriviaQuestion, UserTriviaHistory
from app.schemas.trivia import BallVerifyIn, TriviaSubmitIn
from app.services.trivia import (
    OverNotReady,
    _get_raw_questions_for_date,
    get_ist_today,
    submit_trivia,
    verify_ball,
)
from app.services.trivia_generation import CATEGORY_ORDER, ensure_trivia_bank, fingerprint
from tests.trivia_fixtures import sample_over

pytestmark = pytest.mark.integration


@pytest.fixture
async def engine():
    eng = create_async_engine(Settings().database_url)
    try:
        async with eng.connect():
            pass
    except OSError:
        pytest.skip("Postgres not reachable")
    yield eng
    await eng.dispose()


async def _store_over(engine: AsyncEngine, day: date, balls: list[dict[str, Any]]) -> None:
    async with async_sessionmaker(engine)() as s:
        await s.execute(delete(DailyTriviaQuestion).where(DailyTriviaQuestion.puzzle_date == day))
        s.add_all(
            DailyTriviaQuestion(
                puzzle_date=day,
                fingerprint=f"{fingerprint(b['question'])[:40]}{day.isoformat()}",
                **b,
            )
            for b in balls
        )
        await s.commit()


async def _clear_days(engine: AsyncEngine, *days: date) -> None:
    async with async_sessionmaker(engine)() as s:
        await s.execute(
            delete(DailyTriviaQuestion).where(DailyTriviaQuestion.puzzle_date.in_(days))
        )
        await s.commit()


@pytest.fixture
async def scored_today(engine: AsyncEngine):
    """Stores today's over in the database so it counts for points."""
    today = get_ist_today()
    await _store_over(engine, today, sample_over("today"))
    yield today
    await _clear_days(engine, today)


@pytest.fixture
async def user_id(engine: AsyncEngine):
    maker = async_sessionmaker(engine, expire_on_commit=False)
    uid = uuid.uuid4()
    async with maker() as s:
        s.add(
            User(
                id=uid,
                phone=f"+91{uid.int % 10**10:010d}",
                firebase_uid=f"test-{uid}",
                name="Tester",
            )
        )
        await s.commit()
    yield uid
    async with maker() as s:
        await s.execute(delete(UserTriviaHistory).where(UserTriviaHistory.user_id == uid))
        await s.execute(delete(User).where(User.id == uid))
        await s.commit()


async def _verify(engine: AsyncEngine, uid: uuid.UUID, ball: int, answer: int):
    async with async_sessionmaker(engine, expire_on_commit=False)() as s:
        return await verify_ball(s, uid, BallVerifyIn(ball_number=ball, answer=answer))


async def _submit(engine: AsyncEngine, uid: uuid.UUID):
    async with async_sessionmaker(engine, expire_on_commit=False)() as s:
        return await submit_trivia(s, uid, TriviaSubmitIn(answers=[0] * 6))


async def _state(engine: AsyncEngine, uid: uuid.UUID) -> tuple[dict, int, int]:
    async with async_sessionmaker(engine)() as s:
        history = (
            await s.execute(select(UserTriviaHistory).where(UserTriviaHistory.user_id == uid))
        ).scalar_one()
        user = await s.get(User, uid)
        assert user is not None
        return dict(history.answers), history.points_earned, user.trivia_points


async def _correct_answers(engine: AsyncEngine) -> list[int]:
    async with async_sessionmaker(engine)() as s:
        raw = await _get_raw_questions_for_date(s, get_ist_today())
    return [b["correct_index"] for b in raw]


async def test_parallel_verifies_lock_every_ball(engine, user_id, scored_today) -> None:
    """A burst of verifies for all six balls must record all six answers, not just some."""
    correct = await _correct_answers(engine)
    wrong = [(c + 1) % 4 for c in correct]

    await asyncio.gather(*(_verify(engine, user_id, i + 1, wrong[i]) for i in range(6)))

    # Knowing the answers now, retrying with the correct ones must change nothing.
    for i in range(6):
        result = await _verify(engine, user_id, i + 1, correct[i])
        assert result.is_correct is False

    answers, points_earned, total = await _state(engine, user_id)
    assert answers == {str(i + 1): wrong[i] for i in range(6)}
    assert points_earned == 0
    assert total == 0


async def test_same_ball_raced_with_every_option_keeps_one_answer(
    engine, user_id, scored_today
) -> None:
    await asyncio.gather(*(_verify(engine, user_id, 1, option) for option in range(4)))
    answers, _, _ = await _state(engine, user_id)
    assert list(answers) == ["1"]
    assert answers["1"] in range(4)


async def test_last_ball_and_submit_racing_award_points_once(engine, user_id, scored_today) -> None:
    correct = await _correct_answers(engine)
    for i in range(5):
        await _verify(engine, user_id, i + 1, correct[i])

    await asyncio.gather(
        _verify(engine, user_id, 6, correct[5]),
        _submit(engine, user_id),
        _submit(engine, user_id),
    )

    _, points_earned, total = await _state(engine, user_id)
    assert points_earned == 6
    assert total == 6


async def test_submit_before_answering_reveals_nothing(engine, user_id, scored_today) -> None:
    result = await _submit(engine, user_id)
    assert result.results == []
    assert result.points_earned == 0


async def test_day_without_generated_over_cannot_be_played(engine, user_id) -> None:
    """No built-in bank: nothing is served, verified or recorded until the AI over exists."""
    await _clear_days(engine, get_ist_today())
    with pytest.raises(OverNotReady):
        await _verify(engine, user_id, 1, 0)
    async with async_sessionmaker(engine)() as s:
        rows = (
            await s.execute(select(UserTriviaHistory).where(UserTriviaHistory.user_id == user_id))
        ).all()
    assert rows == []


class FakeLLM:
    """Returns a repeat of an existing question first, then fresh overs."""

    model = "fake-llm"

    def __init__(self, repeat_question: str) -> None:
        self.calls = 0
        self.repeat_question = repeat_question

    async def complete_json(self, **_: Any) -> LLMResult:
        self.calls += 1
        n = self.calls
        balls = [
            {
                "ball_number": i + 1,
                "category": category,
                "difficulty": "easy",
                "question": f"Which zq{n}b{i} player kv{n}c{i} scored the tw{n}d{i} century?",
                "options": [f"a{n}{i}", f"b{n}{i}", f"c{n}{i}", f"d{n}{i}"],
                "correct_index": i % 4,
                "explanation": "Recorded in the scorecard.",
            }
            for i, category in enumerate(CATEGORY_ORDER)
        ]
        if n == 1:
            balls[2]["question"] = self.repeat_question
        return LLMResult(data={"balls": balls}, model=self.model, input_tokens=1, output_tokens=1)


async def test_bank_generation_skips_repeats_and_fills_days(engine) -> None:
    earlier, first, second = date(2031, 1, 1), date(2031, 1, 30), date(2031, 1, 31)
    earlier_over = sample_over("earlier")
    await _store_over(engine, earlier, earlier_over)
    llm = FakeLLM(repeat_question=earlier_over[2]["question"])
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as s:
            result = await ensure_trivia_bank(s, today=first, llm=llm, max_days=2)
        assert result.generated == (first, second)
        assert result.failed == ()
        assert llm.calls == 3  # first attempt rejected for repeating an earlier question

        async with async_sessionmaker(engine)() as s:
            stored = (
                (
                    await s.execute(
                        select(DailyTriviaQuestion.question).where(
                            DailyTriviaQuestion.puzzle_date.in_([first, second])
                        )
                    )
                )
                .scalars()
                .all()
            )
        assert len(stored) == 12
        assert earlier_over[2]["question"] not in stored

        # Running again never regenerates days that are already filled.
        async with async_sessionmaker(engine, expire_on_commit=False)() as s:
            again = await ensure_trivia_bank(s, today=first, llm=llm, max_days=2)
        assert first not in again.generated
        assert second not in again.generated
    finally:
        async with async_sessionmaker(engine)() as s:
            await s.execute(
                delete(DailyTriviaQuestion).where(DailyTriviaQuestion.puzzle_date >= earlier)
            )
            await s.commit()


class SlowLLM(FakeLLM):
    async def complete_json(self, **kwargs: Any) -> LLMResult:
        await asyncio.sleep(0.2)
        return await super().complete_json(**kwargs)


async def test_only_one_generator_runs_at_a_time(engine) -> None:
    day = date(2032, 3, 31)

    async def run() -> Any:
        async with async_sessionmaker(engine, expire_on_commit=False)() as s:
            return await ensure_trivia_bank(s, today=day, llm=SlowLLM("unused"), max_days=1)

    try:
        a, b = await asyncio.gather(run(), run())
        reasons = sorted(str(r.skipped_reason) for r in (a, b))
        assert reasons == ["None", "another run in progress"]
        assert len(a.generated) + len(b.generated) == 1
    finally:
        await _clear_days(engine, day)
