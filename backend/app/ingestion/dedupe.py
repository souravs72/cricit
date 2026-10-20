"""Two-pass duplicate detection with a three-way verdict.

Title similarity alone is unreliable for sports news: "India beat Australia in Perth"
and "India lose to Australia in Perth" score ~92, while a genuine rewording of the same
story can score ~57. So we only auto-merge when we are very sure, send the uncertain
middle band to the admin review queue, and treat the rest as distinct.

Pass 1 (before AI, cheap): canonical URL hash, then near-identical titles within 48 h.
Pass 2 (after AI tags): shared team/player tags within 6 h + title similarity.
Titles whose numbers differ ("3rd ODI" vs "4th ODI", "6 wickets" vs "4 wickets") are
never auto-merged.
"""

import hashlib
import re
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from rapidfuzz import fuzz

_TRACKING = re.compile(r"^(utm_|fbclid$|gclid$|ref$|ref_src$|amp$)")
_WS = re.compile(r"\s+")
_PUNCT = re.compile(r"[^\w\s]")
_NUM = re.compile(r"\d+")

AUTO_MERGE_SIMILARITY = 95
PASS1_REVIEW_SIMILARITY = 85
PASS2_REVIEW_SIMILARITY = 55


class Verdict(StrEnum):
    DISTINCT = "distinct"
    POSSIBLE = "possible"  # publish only after an editor confirms in the review queue
    DUPLICATE = "duplicate"  # merge as an extra source of the existing post


def canonical_url(url: str) -> str:
    parts = urlsplit(url.strip())
    query = [(k, v) for k, v in parse_qsl(parts.query) if not _TRACKING.match(k.lower())]
    path = re.sub(r"/amp$", "", parts.path.rstrip("/")) or "/"
    host = parts.netloc.lower().removeprefix("www.")
    return urlunsplit(("https", host, path, urlencode(query), ""))


def url_hash(url: str) -> str:
    return hashlib.sha256(canonical_url(url).encode()).hexdigest()


def normalise_title(title: str) -> str:
    return _WS.sub(" ", _PUNCT.sub(" ", title.lower())).strip()


def _numbers(title: str) -> set[str]:
    return set(_NUM.findall(title))


@dataclass(frozen=True)
class Candidate:
    title: str
    published_at: datetime
    tags: frozenset[str] = frozenset()


def _compare(new: Candidate, old: Candidate, review_floor: int) -> Verdict:
    a, b = normalise_title(new.title), normalise_title(old.title)
    score = fuzz.token_set_ratio(a, b)
    if score < review_floor:
        return Verdict.DISTINCT
    numbers_conflict = bool(_numbers(a) and _numbers(b) and _numbers(a) != _numbers(b))
    if score >= AUTO_MERGE_SIMILARITY and not numbers_conflict:
        return Verdict.DUPLICATE
    return Verdict.POSSIBLE


def _strongest(verdicts: list[Verdict]) -> Verdict:
    if Verdict.DUPLICATE in verdicts:
        return Verdict.DUPLICATE
    if Verdict.POSSIBLE in verdicts:
        return Verdict.POSSIBLE
    return Verdict.DISTINCT


def check_pass1(new: Candidate, recent: list[Candidate]) -> Verdict:
    window = timedelta(hours=48)
    return _strongest(
        [
            _compare(new, old, PASS1_REVIEW_SIMILARITY)
            for old in recent
            if abs(new.published_at - old.published_at) <= window
        ]
    )


def check_pass2(new: Candidate, recent: list[Candidate]) -> Verdict:
    if not new.tags:
        return Verdict.DISTINCT
    window = timedelta(hours=6)
    return _strongest(
        [
            _compare(new, old, PASS2_REVIEW_SIMILARITY)
            for old in recent
            if abs(new.published_at - old.published_at) <= window
            and len(new.tags & old.tags) >= min(2, len(new.tags))
        ]
    )
