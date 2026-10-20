"""Token, password and TOTP primitives. No database access here; services own state.

- Access tokens: JWT ES256 with a `kid` header so keys can rotate.
- Refresh tokens: 256-bit random strings; only their SHA-256 hash is stored.
- Passwords: Argon2id.
- Admin 2FA: TOTP (RFC 6238) + hashed single-use recovery codes.
"""

import hashlib
import hmac
import secrets
import time
import uuid
from dataclasses import dataclass
from typing import Any, Literal

import jwt
import pyotp
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

from app.core.config import Settings
from app.core.errors import Unauthorized

PrincipalType = Literal["user", "admin"]
_ALG = "ES256"
_hasher = PasswordHasher()  # argon2id with library defaults (tuned for ~50 ms)


@dataclass(frozen=True)
class TokenClaims:
    sub: str
    sid: str
    typ: PrincipalType
    jti: str
    exp: int
    perms: tuple[str, ...] = ()


def _public_keys(settings: Settings) -> dict[str, str]:
    keys: dict[str, str] = {}
    for pair in filter(None, settings.jwt_public_keys.split("||")):
        kid, _, pem = pair.partition("=")
        keys[kid.strip()] = pem.strip().replace("\\n", "\n")
    return keys


def issue_access_token(
    settings: Settings,
    *,
    subject: str,
    session_id: str,
    typ: PrincipalType,
    permissions: tuple[str, ...] = (),
) -> str:
    ttl = settings.admin_access_ttl_s if typ == "admin" else settings.user_access_ttl_s
    now = int(time.time())
    payload: dict[str, Any] = {
        "iss": settings.jwt_issuer,
        "sub": subject,
        "sid": session_id,
        "typ": typ,
        "jti": uuid.uuid4().hex,
        "iat": now,
        "exp": now + ttl,
    }
    if permissions:
        payload["perms"] = list(permissions)
    private_key = settings.jwt_private_key.replace("\\n", "\n")
    return jwt.encode(payload, private_key, algorithm=_ALG, headers={"kid": settings.jwt_key_id})


def decode_access_token(settings: Settings, token: str, *, expected: PrincipalType) -> TokenClaims:
    try:
        kid = jwt.get_unverified_header(token).get("kid")
        key = _public_keys(settings).get(str(kid))
        if key is None:
            raise Unauthorized("Unknown signing key")
        data = jwt.decode(
            token,
            key,
            algorithms=[_ALG],
            issuer=settings.jwt_issuer,
            options={"require": ["exp", "iat", "sub", "sid", "typ", "jti"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise Unauthorized("Session expired") from exc
    except jwt.PyJWTError as exc:
        raise Unauthorized("Invalid token") from exc
    if data["typ"] != expected:
        raise Unauthorized("Wrong token type")
    return TokenClaims(
        sub=data["sub"],
        sid=data["sid"],
        typ=data["typ"],
        jti=data["jti"],
        exp=data["exp"],
        perms=tuple(data.get("perms", ())),
    )


def new_refresh_token() -> tuple[str, str]:
    """Return (token for the client, hash to store)."""
    token = secrets.token_urlsafe(32)
    return token, hash_refresh_token(token)


def hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def tokens_match(stored_hash: str, presented: str) -> bool:
    return hmac.compare_digest(stored_hash, hash_refresh_token(presented))


def hash_password(password: str) -> str:
    if len(password) < 12:
        raise ValueError("Password must be at least 12 characters")
    return _hasher.hash(password)


def verify_password(stored_hash: str, password: str) -> bool:
    try:
        return _hasher.verify(stored_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def password_needs_rehash(stored_hash: str) -> bool:
    return _hasher.check_needs_rehash(stored_hash)


def new_totp_secret() -> str:
    return pyotp.random_base32()


def totp_uri(secret: str, email: str) -> str:
    return pyotp.TOTP(secret).provisioning_uri(name=email, issuer_name="CRICIT Admin")


def verify_totp(secret: str, code: str) -> bool:
    # valid_window=1 accepts the previous/next 30 s step to absorb clock drift.
    return pyotp.TOTP(secret).verify(code, valid_window=1)


def new_recovery_codes(count: int = 10) -> tuple[list[str], list[str]]:
    """Return (codes shown once to the admin, hashes to store)."""
    codes = [f"{secrets.token_hex(3)}-{secrets.token_hex(3)}" for _ in range(count)]
    return codes, [hash_refresh_token(c) for c in codes]
