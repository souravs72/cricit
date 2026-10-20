"""Checks every AI summary must pass before it can publish without review."""

import re
from dataclasses import dataclass

_NUMBER = re.compile(r"\d+(?:[.,]\d+)*")
_DEVANAGARI = re.compile(r"[ऀ-ॿ]")


@dataclass(frozen=True)
class ValidationResult:
    ok: bool
    reasons: tuple[str, ...] = ()


def numbers_in(text: str) -> set[str]:
    return {n.replace(",", "") for n in _NUMBER.findall(text)}


def validate_summary(
    *, summary: str, headline: str, source_text: str, min_words: int = 45, max_words: int = 75
) -> ValidationResult:
    reasons: list[str] = []
    words = len(summary.split())
    if not min_words <= words <= max_words:
        reasons.append(f"summary has {words} words (want {min_words}-{max_words})")
    if len(headline) > 80:
        reasons.append("headline over 80 characters")
    invented = (numbers_in(summary) | numbers_in(headline)) - numbers_in(source_text)
    if invented:
        reasons.append(f"numbers not in source: {sorted(invented)}")
    return ValidationResult(ok=not reasons, reasons=tuple(reasons))


def looks_hindi(text: str, min_ratio: float = 0.5) -> bool:
    letters = [c for c in text if c.isalpha()]
    if not letters:
        return False
    return sum(bool(_DEVANAGARI.match(c)) for c in letters) / len(letters) >= min_ratio
