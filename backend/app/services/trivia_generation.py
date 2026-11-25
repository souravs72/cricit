"""AI generation of the Daily Over question bank, run ahead of time by a worker cron.

Each run fills every missing day from today to the end of next month, so the upcoming
month is always prepared in advance. There is no built-in fallback: the app only ever plays
these generated, point-earning overs.

Repeats are blocked in layers:
1. The prompt lists recent questions to avoid.
2. Every new question is compared with every question ever stored (and with the rest of its
   own over): a reworded question (high word overlap) or the same fact asked differently
   (same correct answer and moderate overlap) is rejected and the over regenerated.
3. A unique fingerprint on the normalised question text blocks exact repeats in the database.
4. A Postgres advisory lock lets only one generator run at a time, so two concurrent runs
   cannot each approve a similar question.
"""

from __future__ import annotations

import hashlib
import re
from calendar import monthrange
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

import structlog
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession

from app.ai.client import LLMClient, LocalDeterministicLLMClient, get_llm_client, load_prompt
from app.models.ads import AiJob
from app.repositories import settings as settings_repo
from app.repositories import trivia_bank as bank_repo
from app.repositories.trivia_bank import StoredQuestion

log = structlog.get_logger()

PROMPT_NAME = "trivia_over_v1"
CATEGORY_ORDER = ("trending", "domestic", "grassroots", "ipl", "international", "rules")
DIFFICULTIES = frozenset({"easy", "medium", "hard"})
NEAR_DUPLICATE_THRESHOLD = 0.6
# Same correct answer + this much overlap = the same fact asked differently.
SAME_FACT_THRESHOLD = 0.35
MAX_ATTEMPTS_PER_DAY = 4
MAX_DAYS_PER_RUN = 12
AVOID_LIST_SIZE = 150
MAX_OUTPUT_TOKENS = 2500

OVER_SCHEMA: dict[str, Any] = {
    "type": "object",
    "required": ["balls"],
    "properties": {
        "balls": {
            "type": "array",
            "minItems": 6,
            "maxItems": 6,
            "items": {
                "type": "object",
                "required": [
                    "ball_number",
                    "category",
                    "difficulty",
                    "question",
                    "options",
                    "correct_index",
                    "explanation",
                ],
                "properties": {
                    "ball_number": {"type": "integer"},
                    "category": {"type": "string"},
                    "difficulty": {"type": "string"},
                    "question": {"type": "string"},
                    "options": {"type": "array", "items": {"type": "string"}},
                    "correct_index": {"type": "integer"},
                    "explanation": {"type": "string"},
                },
            },
        }
    },
}

_STOPWORDS = frozenset(
    [
        "a",
        "an",
        "and",
        "are",
        "as",
        "at",
        "be",
        "by",
        "did",
        "does",
        "for",
        "from",
        "has",
        "have",
        "he",
        "her",
        "his",
        "how",
        "in",
        "is",
        "it",
        "its",
        "of",
        "on",
        "or",
        "the",
        "their",
        "this",
        "to",
        "was",
        "were",
        "what",
        "when",
        "where",
        "which",
        "who",
        "whom",
        "why",
        "with",
    ]
)


class InvalidOver(ValueError):
    """The model's output is not a usable over."""


@dataclass(frozen=True)
class BankRunResult:
    generated: tuple[date, ...]
    failed: tuple[date, ...]
    skipped_reason: str | None = None


# ---------------------------------------------------------------------------
# Pure helpers
# ---------------------------------------------------------------------------


def normalise(text: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", text.lower())).strip()


def fingerprint(question: str) -> str:
    return hashlib.sha256(normalise(question).encode()).hexdigest()


def _stem(word: str) -> str:
    return word[:-1] if len(word) > 3 and word.endswith("s") and not word.endswith("ss") else word


def content_words(text: str) -> frozenset[str]:
    return frozenset(_stem(w) for w in normalise(text).split() if w not in _STOPWORDS)


@dataclass(frozen=True)
class KnownQuestion:
    """What repeat detection needs from a question: its words and its correct answer."""

    words: frozenset[str]
    answer: str


def known_from(question: str, options: list[str] | tuple[str, ...], correct: int) -> KnownQuestion:
    answer = normalise(options[correct]) if 0 <= correct < len(options) else ""
    return KnownQuestion(words=content_words(question), answer=answer)


def _overlap(a: frozenset[str], b: frozenset[str]) -> float:
    union = a | b
    return len(a & b) / len(union) if union else 1.0


def is_repeat(candidate: KnownQuestion, known: list[KnownQuestion]) -> bool:
    """True if the candidate rewords a known question or asks the same fact again."""
    if not candidate.words:
        return True
    for other in known:
        overlap = _overlap(candidate.words, other.words)
        if overlap >= NEAR_DUPLICATE_THRESHOLD:
            return True
        if candidate.answer and candidate.answer == other.answer and overlap >= SAME_FACT_THRESHOLD:
            return True
    return False


def days_to_fill(today: date) -> list[date]:
    """Every day from today through the last day of next month."""
    next_month_first = (today.replace(day=1) + timedelta(days=32)).replace(day=1)
    last = next_month_first.replace(
        day=monthrange(next_month_first.year, next_month_first.month)[1]
    )
    return [today + timedelta(days=i) for i in range((last - today).days + 1)]


def validate_over(data: dict[str, Any]) -> list[dict[str, Any]]:
    """Returns six clean balls in category order, or raises InvalidOver."""
    balls = data.get("balls")
    if not isinstance(balls, list) or len(balls) != len(CATEGORY_ORDER):
        raise InvalidOver("an over needs exactly 6 balls")
    clean: list[dict[str, Any]] = []
    for number, (ball, category) in enumerate(zip(balls, CATEGORY_ORDER, strict=True), start=1):
        clean.append(_validate_ball(ball, number, category))
    return clean


def _validate_ball(ball: Any, number: int, category: str) -> dict[str, Any]:
    if not isinstance(ball, dict):
        raise InvalidOver(f"ball {number} is not an object")
    if ball.get("category") != category:
        raise InvalidOver(f"ball {number} must be {category}")
    question = str(ball.get("question", "")).strip()
    explanation = str(ball.get("explanation", "")).strip()
    options = ball.get("options")
    correct = ball.get("correct_index")
    if not 15 <= len(question) <= 300:
        raise InvalidOver(f"ball {number} question length is out of range")
    if not explanation:
        raise InvalidOver(f"ball {number} has no explanation")
    if not isinstance(options, list) or len(options) != 4:
        raise InvalidOver(f"ball {number} needs 4 options")
    options = [str(o).strip() for o in options]
    if any(not o for o in options) or len({normalise(o) for o in options}) != 4:
        raise InvalidOver(f"ball {number} options must be 4 different, non-empty answers")
    if not isinstance(correct, int) or isinstance(correct, bool) or not 0 <= correct <= 3:
        raise InvalidOver(f"ball {number} correct_index must be 0 to 3")
    difficulty = str(ball.get("difficulty", "medium")).lower()
    return {
        "ball_number": number,
        "category": category,
        "difficulty": difficulty if difficulty in DIFFICULTIES else "medium",
        "question": question,
        "options": options,
        "correct_index": correct,
        "explanation": explanation,
    }


def _known_ball(ball: dict[str, Any]) -> KnownQuestion:
    return known_from(ball["question"], ball["options"], ball["correct_index"])


def find_repeats(balls: list[dict[str, Any]], known: list[KnownQuestion]) -> list[str]:
    """Questions in this over that repeat a known question or another ball in the over."""
    repeats: list[str] = []
    seen = list(known)
    for ball in balls:
        candidate = _known_ball(ball)
        if is_repeat(candidate, seen):
            repeats.append(ball["question"])
        seen.append(candidate)
    return repeats


# ---------------------------------------------------------------------------
# Database + model calls
# ---------------------------------------------------------------------------


async def _llm_for(db: AsyncSession) -> LLMClient:
    app_cfg = await settings_repo.get_settings(db)
    if app_cfg and app_cfg.llm_api_key:
        return get_llm_client(app_cfg)
    return get_llm_client()


def _avoid_list(questions: list[str]) -> str:
    recent = questions[:AVOID_LIST_SIZE]
    return "\n".join(f"- {q}" for q in recent) or "- (none yet)"


async def _ask_for_over(
    db: AsyncSession, llm: LLMClient, day: date, avoid: list[str]
) -> list[dict[str, Any]] | None:
    """One model call, audited in ai_jobs. Returns validated balls or None."""
    version, template = load_prompt(PROMPT_NAME)
    status, error, balls = "ok", None, None
    model, in_tok, out_tok, cost = getattr(llm, "model", "unknown"), 0, 0, 0.0
    try:
        res = await llm.complete_json(
            system="You are a meticulous cricket quiz writer and fact-checker for CRICIT.",
            user=template.format(puzzle_date=day.isoformat(), avoid_list=_avoid_list(avoid)),
            schema=OVER_SCHEMA,
            max_tokens=MAX_OUTPUT_TOKENS,
        )
        model, in_tok, out_tok, cost = res.model, res.input_tokens, res.output_tokens, res.cost_inr
        balls = validate_over(res.data)
    except InvalidOver as exc:
        status, error = "invalid", str(exc)
    except Exception as exc:  # network / provider / JSON errors are retried next run
        status, error = "error", str(exc)[:500]
    db.add(
        AiJob(
            post_id=None,
            model=str(model)[:80],
            prompt_version=version,
            input_tokens=in_tok,
            output_tokens=out_tok,
            cost_inr=cost,
            status=status,
            error=error,
        )
    )
    await db.commit()
    if error:
        log.warning("trivia_generation_rejected", day=day.isoformat(), status=status, error=error)
    return balls


async def generate_day(
    db: AsyncSession, llm: LLMClient, day: date, known: list[StoredQuestion]
) -> list[StoredQuestion] | None:
    """Generates and stores one new over for `day`.

    Returns the stored questions, or None if no clean over was produced this run.
    """
    await bank_repo.delete_incomplete_day(db, day)
    known_checks = [known_from(k.question, k.options, k.correct_index) for k in known]
    known_texts = [k.question for k in known]
    rejected: list[str] = []
    for _ in range(MAX_ATTEMPTS_PER_DAY):
        balls = await _ask_for_over(db, llm, day, rejected + known_texts)
        if balls is None:
            continue
        repeats = find_repeats(balls, known_checks)
        if repeats:
            log.info("trivia_generation_repeat", day=day.isoformat(), count=len(repeats))
            rejected.extend(repeats)
            continue
        await bank_repo.insert_over(
            db, day, [{**b, "fingerprint": fingerprint(b["question"])} for b in balls]
        )
        try:
            await db.commit()
        except IntegrityError:
            # An exact repeat matched a stored fingerprint: regenerate.
            await db.rollback()
            rejected.extend(b["question"] for b in balls)
            continue
        return [
            StoredQuestion(b["question"], tuple(b["options"]), b["correct_index"]) for b in balls
        ]
    return None


async def ensure_trivia_bank(
    db: AsyncSession,
    *,
    today: date,
    llm: LLMClient | None = None,
    max_days: int = MAX_DAYS_PER_RUN,
) -> BankRunResult:
    """Fills missing days from today to the end of next month, nearest days first.

    Safe to run repeatedly and concurrently: only one run generates at a time.
    """
    client = llm or await _llm_for(db)
    if isinstance(client, LocalDeterministicLLMClient):
        log.error("trivia_generation_skipped", reason="no LLM API key configured")
        return BankRunResult(generated=(), failed=(), skipped_reason="no LLM API key configured")

    engine = db.bind
    if not isinstance(engine, AsyncEngine):
        raise TypeError("ensure_trivia_bank needs a session bound to an AsyncEngine")
    async with bank_repo.generator_lock(engine) as acquired:
        if not acquired:
            log.info("trivia_generation_skipped", reason="another run in progress")
            return BankRunResult(generated=(), failed=(), skipped_reason="another run in progress")
        return await _fill_window(db, client, today, max_days)


async def _fill_window(
    db: AsyncSession, llm: LLMClient, today: date, max_days: int
) -> BankRunResult:
    window = days_to_fill(today)
    filled = await bank_repo.filled_days(db, window)
    missing = [d for d in window if d not in filled][:max_days]
    known = await bank_repo.all_questions(db)
    generated: list[date] = []
    failed: list[date] = []
    for day in missing:
        stored = await generate_day(db, llm, day, known)
        if stored is None:
            failed.append(day)
            continue
        generated.append(day)
        known = stored + known
    if today in failed:
        log.error("trivia_today_missing", day=today.isoformat())
    log.info("trivia_bank_run", generated=len(generated), failed=len(failed))
    return BankRunResult(generated=tuple(generated), failed=tuple(failed))
