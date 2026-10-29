"""possible_duplicate_of on posts for T12 review links

Revision ID: 20261029_possdup
Revises: 51d98d967674
Create Date: 2026-10-29 19:30:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20261029_possdup"
down_revision: str | None = "51d98d967674"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("posts", sa.Column("possible_duplicate_of", sa.UUID(), nullable=True))
    op.create_foreign_key(
        op.f("fk_posts_possible_duplicate_of_posts"),
        "posts",
        "posts",
        ["possible_duplicate_of"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(op.f("fk_posts_possible_duplicate_of_posts"), "posts", type_="foreignkey")
    op.drop_column("posts", "possible_duplicate_of")
