"""Daily 6-ball cricket trivia models and user history."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, IdMixin, TimestampMixin


class DailyTriviaQuestion(IdMixin, TimestampMixin, Base):
    __tablename__ = "daily_trivia_questions"
    __table_args__ = (UniqueConstraint("puzzle_date", "ball_number", name="uq_daily_ball"),)

    puzzle_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    ball_number: Mapped[int] = mapped_column(Integer, nullable=False)  # 1 through 6
    category: Mapped[str] = mapped_column(String(50), nullable=False)  # domestic, grassroots, etc.
    difficulty: Mapped[str] = mapped_column(String(20), default="medium")
    question: Mapped[str] = mapped_column(Text, nullable=False)
    # sha256 of the normalised question text; the unique index blocks exact repeats forever.
    fingerprint: Mapped[str | None] = mapped_column(String(64), unique=True)
    options: Mapped[list[str]] = mapped_column(JSONB, nullable=False)
    correct_index: Mapped[int] = mapped_column(Integer, nullable=False)  # 0 to 3
    explanation: Mapped[str] = mapped_column(Text, nullable=False)


class UserTriviaHistory(IdMixin, TimestampMixin, Base):
    __tablename__ = "user_trivia_history"
    __table_args__ = (UniqueConstraint("user_id", "puzzle_date", name="uq_user_daily_trivia"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    puzzle_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    points_earned: Mapped[int] = mapped_column(Integer, nullable=False, default=0)  # 0 to 6
    answers: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
