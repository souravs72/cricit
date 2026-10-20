import os

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec


def _keypair() -> tuple[str, str]:
    key = ec.generate_private_key(ec.SECP256R1())
    private = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()
    public = (
        key.public_key()
        .public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
        .decode()
    )
    return private, public


PRIVATE_K1, PUBLIC_K1 = _keypair()
PRIVATE_K2, PUBLIC_K2 = _keypair()

os.environ.update(
    {
        "ENV": "test",
        "JWT_PRIVATE_KEY": PRIVATE_K1,
        "JWT_KEY_ID": "k1",
        "JWT_PUBLIC_KEYS": f"k1={PUBLIC_K1}||k2={PUBLIC_K2}",
    }
)


@pytest.fixture
def settings():
    from app.core.config import Settings

    return Settings()


@pytest.fixture
def client():
    from fastapi.testclient import TestClient

    from app.main import create_app

    return TestClient(create_app())


@pytest.fixture
def token_for(settings):
    from app.core.permissions import Role, permissions_for
    from app.core.security import issue_access_token

    def _make(role: str | None = None) -> str:
        if role is None:
            return issue_access_token(settings, subject="u1", session_id="s1", typ="user")
        perms = tuple(p.value for p in permissions_for(Role(role)))
        return issue_access_token(
            settings, subject="a1", session_id="s2", typ="admin", permissions=perms
        )

    return _make
