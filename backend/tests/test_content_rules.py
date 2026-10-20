import uuid
from datetime import UTC, datetime, timedelta

import pytest

from app.ai.validators import looks_hindi, validate_summary
from app.core.errors import ValidationFailed
from app.core.permissions import Permission, Role, permissions_for
from app.ingestion.dedupe import (
    Candidate,
    Verdict,
    canonical_url,
    check_pass1,
    check_pass2,
    url_hash,
)
from app.schemas.feed import decode_cursor, encode_cursor

NOW = datetime(2026, 10, 20, 12, tzinfo=UTC)


def test_canonical_url_strips_tracking_and_amp():
    a = "http://www.espncricinfo.com/story/abc/amp?utm_source=x&id=7"
    b = "https://espncricinfo.com/story/abc?id=7"
    assert canonical_url(a) == canonical_url(b)
    assert url_hash(a) == url_hash(b)


def test_pass1_merges_near_identical_titles():
    old = Candidate("India beat Australia by 6 wickets in Perth", NOW)
    new = Candidate("India beat Australia by 6 wickets in Perth!", NOW + timedelta(hours=2))
    assert check_pass1(new, [old]) is Verdict.DUPLICATE


def test_pass1_never_auto_merges_opposite_results():
    old = Candidate("India beat Australia in Perth Test", NOW)
    new = Candidate("India lose to Australia in Perth Test", NOW + timedelta(hours=1))
    assert check_pass1(new, [old]) is Verdict.POSSIBLE  # an editor decides


def test_pass1_never_auto_merges_different_numbers():
    old = Candidate("India beat Australia by 6 wickets in 3rd ODI", NOW)
    new = Candidate("India beat Australia by 4 wickets in 4th ODI", NOW + timedelta(hours=1))
    assert check_pass1(new, [old]) is not Verdict.DUPLICATE


def test_pass1_ignores_old_story():
    old = Candidate("India beat Australia by 6 wickets in Perth", NOW - timedelta(days=3))
    new = Candidate("India beat Australia by 6 wickets in Perth", NOW)
    assert check_pass1(new, [old]) is Verdict.DISTINCT


def test_pass2_flags_reworded_story_for_review():
    tags = frozenset({"virat kohli", "india"})
    old = Candidate("Kohli hits 50th ODI hundred", NOW, tags)
    new = Candidate("Virat Kohli reaches 50 ODI centuries", NOW + timedelta(hours=1), tags)
    later = Candidate("Virat Kohli reaches 50 ODI centuries", NOW + timedelta(hours=9), tags)
    other = Candidate("Kohli out for a duck in 3rd ODI", NOW + timedelta(hours=1), tags)
    assert check_pass2(new, [old]) is Verdict.POSSIBLE
    assert check_pass2(later, [old]) is Verdict.DISTINCT
    assert check_pass2(other, [old]) is Verdict.DISTINCT


def test_summary_validator_flags_invented_numbers():
    source = "India scored 287 for 5. Gill made 104."
    summary = " ".join(["word"] * 55) + " India scored 300."
    result = validate_summary(summary=summary, headline="India win", source_text=source)
    assert not result.ok
    assert any("300" in r for r in result.reasons)


def test_summary_validator_passes_clean_summary():
    source = "India scored 287 for 5. Gill made 104."
    summary = " ".join(["word"] * 55) + " India scored 287 and Gill made 104."
    assert validate_summary(
        summary=summary, headline="Gill 104 powers India", source_text=source
    ).ok


def test_hindi_detection():
    assert looks_hindi("भारत ने ऑस्ट्रेलिया को छह विकेट से हराया")
    assert not looks_hindi("India beat Australia")


def test_cursor_round_trip_and_rejects_garbage():
    pid = uuid.uuid4()
    assert decode_cursor(encode_cursor(NOW, pid)) == (NOW, pid)
    with pytest.raises(ValidationFailed):
        decode_cursor("not-a-cursor")


def test_role_matrix_matches_plan():
    editor = permissions_for(Role.EDITOR)
    assert Permission.POSTS_PUBLISH in editor
    assert Permission.ADS_MANAGE not in editor
    assert Permission.ADMINS_MANAGE not in editor
    assert permissions_for(Role.VIEWER) == {Permission.DASHBOARD_VIEW}
    assert permissions_for(Role.OWNER) == set(Permission)
