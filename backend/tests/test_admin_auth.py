from datetime import UTC, datetime, timedelta
from types import SimpleNamespace

from app.services.admin_auth import (
    GENERIC_LOGIN,
    LOCK_AFTER,
    is_locked,
    register_failure,
    register_success,
)


def test_lockout_after_five_failures() -> None:
    now = datetime(2026, 10, 28, 12, tzinfo=UTC)
    admin = SimpleNamespace(failed_logins=0, locked_until=None)
    for _ in range(LOCK_AFTER):
        register_failure(admin, now)  # type: ignore[arg-type]
    assert is_locked(admin, now + timedelta(minutes=1))  # type: ignore[arg-type]
    assert not is_locked(admin, now + timedelta(minutes=16))  # type: ignore[arg-type]


def test_success_clears_lockout() -> None:
    now = datetime(2026, 10, 28, 12, tzinfo=UTC)
    admin = SimpleNamespace(failed_logins=4, locked_until=now + timedelta(minutes=15))
    register_success(admin)  # type: ignore[arg-type]
    assert admin.failed_logins == 0
    assert admin.locked_until is None


def test_login_error_copy_does_not_reveal_whether_email_exists() -> None:
    assert "wrong" in GENERIC_LOGIN.lower()
    assert "email" in GENERIC_LOGIN.lower()
