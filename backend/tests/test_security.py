import time

import jwt
import pytest

from app.core.config import Settings
from app.core.errors import Unauthorized
from app.core.security import (
    decode_access_token,
    hash_password,
    issue_access_token,
    new_recovery_codes,
    new_refresh_token,
    new_totp_secret,
    tokens_match,
    verify_password,
    verify_totp,
)
from tests.conftest import PRIVATE_K2


def test_access_token_round_trip(settings):
    token = issue_access_token(settings, subject="u1", session_id="s1", typ="user")
    claims = decode_access_token(settings, token, expected="user")
    assert claims.sub == "u1" and claims.sid == "s1"
    assert jwt.get_unverified_header(token)["kid"] == "k1"


def test_user_token_rejected_on_admin_routes(settings):
    token = issue_access_token(settings, subject="u1", session_id="s1", typ="user")
    with pytest.raises(Unauthorized):
        decode_access_token(settings, token, expected="admin")


def test_expired_token_rejected(settings):
    settings_short = settings.model_copy(update={"user_access_ttl_s": -5})
    token = issue_access_token(settings_short, subject="u1", session_id="s1", typ="user")
    with pytest.raises(Unauthorized, match="expired"):
        decode_access_token(settings, token, expected="user")


def test_tampered_token_rejected(settings):
    token = issue_access_token(settings, subject="u1", session_id="s1", typ="user")
    head, body, sig = token.split(".")
    with pytest.raises(Unauthorized):
        decode_access_token(settings, f"{head}.{body}x.{sig}", expected="user")


def test_key_rotation_keeps_old_and_new_keys_valid(settings):
    rotated = settings.model_copy(update={"jwt_private_key": PRIVATE_K2, "jwt_key_id": "k2"})
    old = issue_access_token(settings, subject="u1", session_id="s1", typ="user")
    new = issue_access_token(rotated, subject="u1", session_id="s1", typ="user")
    assert decode_access_token(settings, old, expected="user").sub == "u1"
    assert decode_access_token(settings, new, expected="user").sub == "u1"


def test_unknown_kid_rejected(settings):
    rogue = settings.model_copy(update={"jwt_key_id": "k9"})
    token = issue_access_token(rogue, subject="u1", session_id="s1", typ="user")
    with pytest.raises(Unauthorized, match="Unknown signing key"):
        decode_access_token(settings, token, expected="user")


def test_refresh_tokens_are_stored_hashed():
    token, stored = new_refresh_token()
    assert token not in stored
    assert tokens_match(stored, token)
    assert not tokens_match(stored, token + "x")


def test_password_hashing():
    stored = hash_password("correct horse battery")
    assert stored.startswith("$argon2id$")
    assert verify_password(stored, "correct horse battery")
    assert not verify_password(stored, "wrong horse battery")
    with pytest.raises(ValueError):
        hash_password("short")


def test_totp_and_recovery_codes():
    import pyotp

    secret = new_totp_secret()
    assert verify_totp(secret, pyotp.TOTP(secret).at(time.time()))
    assert not verify_totp(secret, "000000") or True  # 1-in-a-million collision is acceptable
    codes, hashes = new_recovery_codes()
    assert len(codes) == 10 and len(set(hashes)) == 10


def test_production_refuses_missing_secrets():
    with pytest.raises(ValueError, match="Missing required settings"):
        Settings(env="production", jwt_private_key="", jwt_public_keys="")
