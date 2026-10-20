"""Print a fresh ES256 key pair as .env lines. Usage: uv run python scripts/gen_keys.py [kid]

Rotation: generate a new kid, set it as JWT_PRIVATE_KEY/JWT_KEY_ID, and APPEND its public key to
JWT_PUBLIC_KEYS ("k1=...||k2=..."). Remove the old public key after the longest token lifetime.
"""

import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec


def main() -> None:
    kid = sys.argv[1] if len(sys.argv) > 1 else "k1"
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
    one_line = lambda pem: pem.strip().replace("\n", "\\n")  # noqa: E731
    print(f'JWT_KEY_ID="{kid}"')
    print(f'JWT_PRIVATE_KEY="{one_line(private)}"')
    print(f'JWT_PUBLIC_KEYS="{kid}={one_line(public)}"')


if __name__ == "__main__":
    main()
