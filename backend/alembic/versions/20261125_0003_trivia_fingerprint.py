"""add question fingerprint so generated trivia never repeats

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-25 14:30:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "daily_trivia_questions",
        sa.Column("fingerprint", sa.String(length=64), nullable=True),
    )
    op.create_unique_constraint(
        op.f("uq_daily_trivia_questions_fingerprint"),
        "daily_trivia_questions",
        ["fingerprint"],
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("uq_daily_trivia_questions_fingerprint"), "daily_trivia_questions", type_="unique"
    )
    op.drop_column("daily_trivia_questions", "fingerprint")
