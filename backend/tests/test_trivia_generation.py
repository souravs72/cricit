"""Pure rules of the AI trivia bank generator: validation, repeats and the fill window."""

from datetime import date

import pytest

from app.services.trivia_generation import (
    CATEGORY_ORDER,
    InvalidOver,
    days_to_fill,
    find_repeats,
    fingerprint,
    is_repeat,
    known_from,
    validate_over,
)

QUESTIONS = (
    "Which bowler took a hat-trick in the opening Test at Perth last season?",
    "Who captained Mumbai to their most recent Ranji Trophy triumph?",
    "Which school tournament in Mumbai is played at Azad Maidan?",
    "Which franchise has lifted the IPL trophy five times under Dhoni?",
    "Which country hosted the first ever Cricket World Cup in 1975?",
    "How many penalty runs are awarded when the ball hits a grounded helmet?",
)


def make_over() -> dict:
    return {
        "balls": [
            {
                "ball_number": i + 1,
                "category": category,
                "difficulty": "medium",
                "question": QUESTIONS[i],
                "options": [f"Option A{i}", f"Option B{i}", f"Option C{i}", f"Option D{i}"],
                "correct_index": i % 4,
                "explanation": "Because it is so.",
            }
            for i, category in enumerate(CATEGORY_ORDER)
        ]
    }


def test_validate_over_accepts_a_good_over() -> None:
    balls = validate_over(make_over())
    assert [b["category"] for b in balls] == list(CATEGORY_ORDER)
    assert [b["ball_number"] for b in balls] == [1, 2, 3, 4, 5, 6]


@pytest.mark.parametrize(
    ("ball_index", "field", "value"),
    [
        (0, "category", "ipl"),
        (1, "options", ["a", "b", "c"]),
        (2, "options", ["Same", "same", "Other", "Another"]),
        (3, "correct_index", 4),
        (4, "correct_index", True),
        (5, "explanation", "  "),
        (0, "question", "Too short?"),
    ],
)
def test_validate_over_rejects_bad_balls(ball_index: int, field: str, value: object) -> None:
    over = make_over()
    over["balls"][ball_index][field] = value
    with pytest.raises(InvalidOver):
        validate_over(over)


def test_validate_over_rejects_wrong_ball_count() -> None:
    over = make_over()
    over["balls"] = over["balls"][:5]
    with pytest.raises(InvalidOver):
        validate_over(over)


def test_validate_over_defaults_unknown_difficulty() -> None:
    over = make_over()
    over["balls"][0]["difficulty"] = "impossible"
    assert validate_over(over)[0]["difficulty"] == "medium"


def test_fingerprint_ignores_case_spacing_and_punctuation() -> None:
    assert fingerprint("Who won the 2011 World Cup?") == fingerprint(
        "  who WON the 2011 world cup "
    )


def test_reworded_question_is_a_repeat() -> None:
    known = [
        known_from(
            "Which team won the Ranji Trophy title in the 2023-24 season?",
            ["Mumbai", "Vidarbha", "Bengal", "Delhi"],
            0,
        )
    ]
    reworded = known_from(
        "Which team won the 2023-24 Ranji Trophy titles?", ["Mumbai", "Kerala", "Assam", "Goa"], 0
    )
    unrelated = known_from(
        "How many penalty runs for hitting a fielder's helmet?", ["5", "4", "6", "2"], 0
    )
    assert is_repeat(reworded, known)
    assert not is_repeat(unrelated, known)


def test_same_fact_asked_differently_is_a_repeat() -> None:
    """Same correct answer and a shared subject: the same fact, even with new wording."""
    known = [
        known_from(
            "Who scored a triple century for Karnataka in the Ranji final?",
            ["Karun Nair", "KL Rahul", "Mayank Agarwal", "Manish Pandey"],
            0,
        )
    ]
    same_fact = known_from(
        "Name the Karnataka batter with a Ranji final triple hundred.",
        ["Manish Pandey", "Karun Nair", "Devdutt Padikkal", "KL Rahul"],
        1,
    )
    same_answer_new_fact = known_from(
        "Which batter made a Test 303* against England at Chennai?",
        ["Karun Nair", "Virender Sehwag", "Rahul Dravid", "VVS Laxman"],
        0,
    )
    assert is_repeat(same_fact, known)
    assert not is_repeat(same_answer_new_fact, known)


def test_empty_question_counts_as_repeat() -> None:
    assert is_repeat(known_from("the of and", ["a", "b", "c", "d"], 0), [])


def test_a_varied_over_has_no_repeats() -> None:
    assert find_repeats(validate_over(make_over()), []) == []


def test_find_repeats_catches_repeats_inside_one_over() -> None:
    balls = validate_over(make_over())
    balls[1] = {**balls[1], "question": balls[0]["question"]}
    assert find_repeats(balls, []) == [balls[0]["question"]]


def test_find_repeats_against_previous_months() -> None:
    balls = validate_over(make_over())
    known = [known_from(balls[3]["question"], balls[3]["options"], balls[3]["correct_index"])]
    assert find_repeats(balls, known) == [balls[3]["question"]]


def test_days_to_fill_runs_to_end_of_next_month() -> None:
    days = days_to_fill(date(2026, 11, 25))
    assert days[0] == date(2026, 11, 25)
    assert days[-1] == date(2026, 12, 31)
    assert len(days) == 37


def test_days_to_fill_handles_year_end_and_february() -> None:
    assert days_to_fill(date(2026, 12, 31))[-1] == date(2027, 1, 31)
    assert days_to_fill(date(2028, 1, 15))[-1] == date(2028, 2, 29)
