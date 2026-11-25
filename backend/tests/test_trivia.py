"""Unit and API-layer tests for daily 6-ball cricket trivia.

Covers:
  - Public question endpoint (GET /v1/trivia/daily): returns 6 balls, no answers exposed.
  - Ball verification endpoint (POST /v1/trivia/verify): requires auth, records choices, anti-cheat.
  - Profile gating ("right details"): user must have phone and display name.
  - Submit protection (POST /v1/trivia/submit): 401 for unauthenticated calls.
  - Point-farming protection: 400 if client attempts to submit for non-current date.
  - Idempotency guard: already_submitted=True on repeat submission, no double points.
  - No built-in bank: a day without a generated over returns 404 over_not_ready.
"""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi.testclient import TestClient

from app.core.db import get_session
from app.core.errors import AppError
from app.main import create_app
from app.models.accounts import User
from app.schemas.trivia import BallVerifyIn, TriviaSubmitIn
from app.services.trivia import (
    OverNotReady,
    get_daily_over,
    record_answer,
    score_answers,
    submit_trivia,
    verify_ball,
)
from tests.trivia_fixtures import sample_over


def _rows_result(balls: list[dict]) -> MagicMock:
    result = MagicMock()
    result.scalars.return_value.all.return_value = [SimpleNamespace(**b) for b in balls]
    return result


def _client_with(balls: list[dict]) -> TestClient:
    app = create_app()
    mock_session = AsyncMock()
    mock_session.execute.return_value = _rows_result(balls)

    async def _override():
        yield mock_session

    app.dependency_overrides[get_session] = _override
    return TestClient(app)


@pytest.fixture
def trivia_client() -> TestClient:
    """A day with a generated over stored."""
    return _client_with(sample_over())


def test_daily_trivia_404_when_no_generated_over() -> None:
    """There is no built-in bank: an empty day is 'being prepared', never a practice over."""
    res = _client_with([]).get("/v1/trivia/daily")
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "over_not_ready"


# ---------------------------------------------------------------------------
# GET /v1/trivia/daily — Public, answers hidden
# ---------------------------------------------------------------------------


def test_daily_trivia_public_no_auth(trivia_client: TestClient) -> None:
    res = trivia_client.get("/v1/trivia/daily")
    assert res.status_code == 200
    body = res.json()
    assert body["total_balls"] == 6
    assert len(body["balls"]) == 6


def test_daily_trivia_does_not_leak_correct_answers(trivia_client: TestClient) -> None:
    """Security check: public endpoint must NOT expose correct_index or explanation."""
    res = trivia_client.get("/v1/trivia/daily")
    assert res.status_code == 200
    for ball in res.json()["balls"]:
        assert "correct_index" not in ball
        assert "explanation" not in ball
        assert len(ball["options"]) == 4


def test_daily_trivia_ball_numbering(trivia_client: TestClient) -> None:
    res = trivia_client.get("/v1/trivia/daily")
    balls = res.json()["balls"]
    assert [b["ball_number"] for b in balls] == [1, 2, 3, 4, 5, 6]


# ---------------------------------------------------------------------------
# POST /v1/trivia/verify — Auth protection
# ---------------------------------------------------------------------------


def test_verify_ball_endpoint_requires_auth(trivia_client: TestClient) -> None:
    """Anti-cheat: /verify cannot be scraped without authentication."""
    res = trivia_client.post("/v1/trivia/verify", json={"ball_number": 1, "answer": 1})
    assert res.status_code == 401


# ---------------------------------------------------------------------------
# POST /v1/trivia/submit & GET /v1/trivia/stats — Auth protection
# ---------------------------------------------------------------------------


def test_submit_trivia_requires_auth(trivia_client: TestClient) -> None:
    res = trivia_client.post("/v1/trivia/submit", json={"answers": [0, 0, 0, 0, 0, 0]})
    assert res.status_code == 401


def test_get_trivia_stats_requires_auth(trivia_client: TestClient) -> None:
    res = trivia_client.get("/v1/trivia/stats")
    assert res.status_code == 401


def test_submit_trivia_rejects_past_dates() -> None:
    """Farming guard: attempting to submit for a past date must be rejected."""
    mock_session = AsyncMock()
    user_id = uuid.uuid4()
    past_date = date.today() - timedelta(days=5)
    payload = TriviaSubmitIn(date=past_date, answers=[0, 1, 2, 0, 1, 2])

    with pytest.raises(AppError) as exc_info:
        import asyncio

        asyncio.run(submit_trivia(mock_session, user_id=user_id, payload=payload))
    assert "current day" in str(exc_info.value).lower()


# ---------------------------------------------------------------------------
# "Right details" gating
# ---------------------------------------------------------------------------


def _user(phone: str | None = "+919876543210", name: str | None = "Sachin") -> MagicMock:
    user = MagicMock(spec=User)
    user.phone = phone
    user.name = name
    user.deleted_at = None
    user.trivia_points = 0
    return user


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("user", "message"),
    [
        (None, "user not found"),
        (_user(phone=None), "phone number required"),
        (_user(name=""), "profile name"),
        (_user(name="   "), "profile name"),
    ],
)
async def test_verify_ball_rejects_users_without_right_details(user, message) -> None:
    mock_session = AsyncMock()
    mock_session.get.return_value = user
    with pytest.raises(AppError) as exc_info:
        await verify_ball(mock_session, uuid.uuid4(), BallVerifyIn(ball_number=1, answer=0))
    assert message in str(exc_info.value).lower()


@pytest.mark.asyncio
async def test_submit_rejects_deleted_user() -> None:
    mock_session = AsyncMock()
    deleted = _user()
    deleted.deleted_at = datetime.now(UTC)
    mock_session.get.return_value = deleted
    with pytest.raises(AppError):
        await submit_trivia(mock_session, uuid.uuid4(), TriviaSubmitIn(answers=[0] * 6))


# ---------------------------------------------------------------------------
# Pure scoring and lock-in rules
# ---------------------------------------------------------------------------


def test_record_answer_locks_first_answer() -> None:
    first = record_answer({}, 1, 2)
    assert first == {"1": 2}
    assert record_answer(first, 1, 3) == {"1": 2}


def test_record_answer_does_not_mutate_input() -> None:
    original: dict[str, int] = {"1": 0}
    updated = record_answer(original, 2, 3)
    assert original == {"1": 0}
    assert updated == {"1": 0, "2": 3}


def test_score_answers_counts_only_correct_balls() -> None:
    raw = sample_over()
    all_correct = {str(b["ball_number"]): b["correct_index"] for b in raw}
    assert score_answers(all_correct, raw) == 6
    three_wrong = {k: (v + 1) % 4 if int(k) <= 3 else v for k, v in all_correct.items()}
    assert score_answers(three_wrong, raw) == 3
    assert score_answers({}, raw) == 0


@pytest.mark.asyncio
async def test_get_daily_over_service() -> None:
    mock_session = AsyncMock()
    mock_session.execute.return_value = _rows_result(sample_over())

    result = await get_daily_over(mock_session)
    assert result.total_balls == 6
    assert len(result.balls) == 6


@pytest.mark.asyncio
async def test_get_daily_over_rejects_incomplete_day() -> None:
    mock_session = AsyncMock()
    mock_session.execute.return_value = _rows_result(sample_over()[:5])
    with pytest.raises(OverNotReady):
        await get_daily_over(mock_session)
