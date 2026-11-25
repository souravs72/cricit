"""Service layer for daily 6-ball trivia and points accumulation."""

import uuid
from datetime import UTC, date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import desc, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError, NotFound
from app.models.accounts import User
from app.models.base import uuid7
from app.models.trivia import DailyTriviaQuestion, UserTriviaHistory
from app.schemas.trivia import (
    BallVerifyIn,
    BallVerifyOut,
    DailyTriviaOverOut,
    TriviaBallQuestion,
    TriviaBallResult,
    TriviaSubmitIn,
    TriviaSubmitOut,
)

IST = ZoneInfo("Asia/Kolkata")


def get_ist_today() -> date:
    """Returns the current calendar date in Indian Standard Time (UTC+05:30)."""
    return datetime.now(IST).date()


class OverNotReady(NotFound):
    """No generated over is stored for the day yet."""

    code = "over_not_ready"


async def _get_raw_questions_for_date(
    session: AsyncSession, query_date: date
) -> list[dict[str, Any]]:
    """Returns the day's six generated questions, answers included (server-side only).

    There is no built-in fallback bank: every over that can be played earns points, and
    its answers never ship inside the app.
    """
    stmt = (
        select(DailyTriviaQuestion)
        .where(DailyTriviaQuestion.puzzle_date == query_date)
        .order_by(DailyTriviaQuestion.ball_number)
    )
    rows = (await session.execute(stmt)).scalars().all()
    if len(rows) == 6:
        balls = [
            {
                "ball_number": r.ball_number,
                "category": r.category,
                "difficulty": r.difficulty,
                "question": r.question,
                "options": r.options,
                "correct_index": r.correct_index,
                "explanation": r.explanation,
            }
            for r in rows
        ]
        return balls
    raise OverNotReady("Today's over is being prepared. Check back soon.")


async def get_daily_over(
    session: AsyncSession, query_date: date | None = None
) -> DailyTriviaOverOut:
    """Returns today's 6-ball trivia questions in IST.

    Answers and explanations are omitted to prevent pre-submission inspection.
    """
    target_date = query_date or get_ist_today()
    raw_balls = await _get_raw_questions_for_date(session, target_date)
    public_balls = [
        TriviaBallQuestion(
            ball_number=b["ball_number"],
            category=b["category"],
            difficulty=b["difficulty"],
            question=b["question"],
            options=b["options"],
        )
        for b in raw_balls
    ]
    return DailyTriviaOverOut(date=target_date, balls=public_balls, total_balls=6)


def _require_right_details(user: User | None) -> User:
    """Points are only for signed-in users with a phone and a display name."""
    if user is None or user.deleted_at is not None:
        raise AppError("User not found")
    if not user.phone:
        raise AppError("Phone number required to record trivia points")
    if not user.name or not user.name.strip():
        raise AppError("Please set up your profile name to play for points", field="name")
    return user


def record_answer(answers: dict[str, Any], ball_number: int, answer: int) -> dict[str, Any]:
    """Returns a new answers map with this ball locked in. An existing answer always wins."""
    key = str(ball_number)
    if key in answers:
        return dict(answers)
    return {**answers, key: answer}


def score_answers(answers: dict[str, Any], raw_balls: list[dict[str, Any]]) -> int:
    """One point per ball whose recorded answer matches the correct option."""
    return sum(1 for b in raw_balls if answers.get(str(b["ball_number"])) == b["correct_index"])


async def _lock_today_history(
    session: AsyncSession, user_id: uuid.UUID, day: date
) -> UserTriviaHistory:
    """Creates today's row if missing, then locks it for the rest of the transaction.

    The row lock serialises concurrent verify/submit calls for the same user and day, so a
    burst of parallel requests can neither overwrite each other's locked answers nor award
    the over twice.
    """
    await session.execute(
        pg_insert(UserTriviaHistory)
        .values(id=uuid7(), user_id=user_id, puzzle_date=day, points_earned=0, answers={})
        .on_conflict_do_nothing(constraint="uq_user_daily_trivia")
    )
    stmt = (
        select(UserTriviaHistory)
        .where(UserTriviaHistory.user_id == user_id, UserTriviaHistory.puzzle_date == day)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    return (await session.execute(stmt)).scalar_one()


async def _finalize_if_complete(
    session: AsyncSession,
    history: UserTriviaHistory,
    raw_balls: list[dict[str, Any]],
) -> int | None:
    """Scores a fully answered, unsubmitted over and adds the points in SQL.

    Returns the user's new total, or None when nothing was awarded.
    """
    if history.submitted_at is not None or len(history.answers) < len(raw_balls):
        return None
    score = score_answers(history.answers, raw_balls)
    history.points_earned = score
    history.submitted_at = datetime.now(UTC)
    result = await session.execute(
        update(User)
        .where(User.id == history.user_id)
        .values(trivia_points=User.trivia_points + score)
        .returning(User.trivia_points)
    )
    return int(result.scalar_one())


async def verify_ball(
    session: AsyncSession,
    user_id: uuid.UUID,
    payload: BallVerifyIn,
    query_date: date | None = None,
) -> BallVerifyOut:
    """Records the user's choice for this ball and reveals the answer.

    The first answer for a ball is locked in; later calls only read it back.
    Requires a signed-in user with a phone and a display name ('right details').
    """
    user = _require_right_details(await session.get(User, user_id))

    today = query_date or get_ist_today()
    raw_balls = await _get_raw_questions_for_date(session, today)
    ball = next((b for b in raw_balls if b["ball_number"] == payload.ball_number), None)
    if ball is None:
        raise AppError(f"Invalid ball number {payload.ball_number}")
    history = await _lock_today_history(session, user_id, today)
    total_points = user.trivia_points
    if history.submitted_at is None:
        history.answers = record_answer(history.answers or {}, payload.ball_number, payload.answer)
        new_total = await _finalize_if_complete(session, history, raw_balls)
        if new_total is not None:
            total_points = new_total
    await session.commit()

    user_choice = history.answers.get(str(payload.ball_number), payload.answer)
    correct_idx = ball["correct_index"]
    return BallVerifyOut(
        ball_number=payload.ball_number,
        user_answer=user_choice,
        is_correct=user_choice == correct_idx,
        correct_index=correct_idx,
        explanation=ball["explanation"],
        points_earned=history.points_earned,
        total_points=total_points,
        is_over_completed=history.submitted_at is not None,
    )


async def submit_trivia(
    session: AsyncSession,
    user_id: uuid.UUID,
    payload: TriviaSubmitIn,
) -> TriviaSubmitOut:
    """Finalizes or retrieves the scorecard for today's over.

    Scoring uses only the answers the server recorded through /verify; the answers the
    client sends here are ignored.
    """
    today = get_ist_today()
    if payload.date is not None and payload.date != today:
        raise AppError("Trivia can only be submitted for the current day")

    user = _require_right_details(await session.get(User, user_id))
    streak = await _calculate_streak(session, user_id, today)
    raw_balls = await _get_raw_questions_for_date(session, today)
    history = await _lock_today_history(session, user_id, today)
    total_points = user.trivia_points
    new_total = await _finalize_if_complete(session, history, raw_balls)
    if new_total is not None:
        total_points = new_total
    await session.commit()

    answers = history.answers or {}
    results = [
        TriviaBallResult(
            ball_number=b["ball_number"],
            user_answer=answers.get(str(b["ball_number"]), -1),
            is_correct=answers.get(str(b["ball_number"])) == b["correct_index"],
            correct_index=b["correct_index"],
            explanation=b["explanation"],
        )
        for b in raw_balls
        if str(b["ball_number"]) in answers
    ]
    completed = history.submitted_at is not None
    return TriviaSubmitOut(
        points_earned=history.points_earned,
        total_points=total_points,
        streak_days=streak + (1 if completed else 0),
        already_submitted=completed and new_total is None,
        results=results,
    )


async def _calculate_streak(session: AsyncSession, user_id: uuid.UUID, current_date: date) -> int:
    stmt = (
        select(UserTriviaHistory.puzzle_date)
        .where(
            UserTriviaHistory.user_id == user_id,
            UserTriviaHistory.puzzle_date < current_date,
            UserTriviaHistory.submitted_at.isnot(None),
        )
        .order_by(desc(UserTriviaHistory.puzzle_date))
        .limit(30)
    )
    dates = (await session.execute(stmt)).scalars().all()
    streak = 0
    check_day = current_date - timedelta(days=1)
    for d in dates:
        if d == check_day:
            streak += 1
            check_day -= timedelta(days=1)
        else:
            break
    return streak
