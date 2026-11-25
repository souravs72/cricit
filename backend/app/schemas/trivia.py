"""Schemas for daily 6-ball trivia, verification, and score submission."""

from __future__ import annotations

import datetime as dt

from pydantic import BaseModel, Field


class TriviaBallQuestion(BaseModel):
    """Public question representation.

    Does not contain correct_index or explanation to prevent client-side inspection exploits.
    """

    ball_number: int = Field(ge=1, le=6)
    category: str
    difficulty: str = "medium"
    question: str
    options: list[str] = Field(min_length=4, max_length=4)


class DailyTriviaOverOut(BaseModel):
    date: dt.date
    balls: list[TriviaBallQuestion] = Field(min_length=6, max_length=6)
    total_balls: int = 6


class BallVerifyIn(BaseModel):
    ball_number: int = Field(ge=1, le=6)
    answer: int = Field(ge=0, le=3)


class BallVerifyOut(BaseModel):
    ball_number: int
    # The answer locked in for this ball (the first one sent), which may differ from this call's.
    user_answer: int
    is_correct: bool
    correct_index: int
    explanation: str
    points_earned: int = 0
    total_points: int = 0
    is_over_completed: bool = False


class TriviaBallResult(BaseModel):
    ball_number: int
    user_answer: int
    is_correct: bool
    correct_index: int
    explanation: str


class TriviaSubmitIn(BaseModel):
    answers: list[int] | None = None
    date: dt.date | None = None


class TriviaSubmitOut(BaseModel):
    points_earned: int = Field(ge=0, le=6)
    total_points: int
    streak_days: int
    already_submitted: bool = False
    results: list[TriviaBallResult] = Field(default_factory=list)
