"""Sample generated overs for trivia tests (stand-ins for AI output)."""

from __future__ import annotations

from typing import Any

CATEGORIES = ("trending", "domestic", "grassroots", "ipl", "international", "rules")

_QUESTIONS = (
    "Which bowler took a hat-trick in the opening Test at Perth last season?",
    "Who captained Mumbai to their most recent Ranji Trophy triumph?",
    "Which school tournament in Mumbai is played at Azad Maidan?",
    "Which franchise has lifted the IPL trophy five times under Dhoni?",
    "Which country hosted the first ever Cricket World Cup in 1975?",
    "How many penalty runs are awarded when the ball hits a grounded helmet?",
)


def sample_over(tag: str = "") -> list[dict[str, Any]]:
    """Six valid balls in category order. `tag` makes the question text unique per over."""
    return [
        {
            "ball_number": i + 1,
            "category": category,
            "difficulty": "medium",
            "question": f"{_QUESTIONS[i]} {tag}".strip(),
            "options": [f"Option A{i}", f"Option B{i}", f"Option C{i}", f"Option D{i}"],
            "correct_index": i % 4,
            "explanation": "Recorded in the official scorecard.",
        }
        for i, category in enumerate(CATEGORIES)
    ]
