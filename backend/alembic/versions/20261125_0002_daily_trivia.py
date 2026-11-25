"""add daily trivia questions and user trivia history

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-25 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. Add trivia_points to users table if not exists
    op.add_column(
        "users",
        sa.Column("trivia_points", sa.Integer(), server_default="0", nullable=False),
    )

    # 2. Create daily_trivia_questions table
    op.create_table(
        "daily_trivia_questions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("puzzle_date", sa.Date(), nullable=False),
        sa.Column("ball_number", sa.Integer(), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=False),
        sa.Column("difficulty", sa.String(length=20), server_default="medium", nullable=False),
        sa.Column("question", sa.Text(), nullable=False),
        sa.Column("options", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("correct_index", sa.Integer(), nullable=False),
        sa.Column("explanation", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("puzzle_date", "ball_number", name="uq_daily_ball"),
    )
    op.create_index(
        op.f("ix_daily_trivia_questions_puzzle_date"),
        "daily_trivia_questions",
        ["puzzle_date"],
        unique=False,
    )

    # 3. Create user_trivia_history table
    op.create_table(
        "user_trivia_history",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("puzzle_date", sa.Date(), nullable=False),
        sa.Column("points_earned", sa.Integer(), server_default="0", nullable=False),
        sa.Column("answers", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "puzzle_date", name="uq_user_daily_trivia"),
    )
    op.create_index(
        op.f("ix_user_trivia_history_user_id"),
        "user_trivia_history",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_user_trivia_history_puzzle_date"),
        "user_trivia_history",
        ["puzzle_date"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_table("user_trivia_history")
    op.drop_table("daily_trivia_questions")
    op.drop_column("users", "trivia_points")
