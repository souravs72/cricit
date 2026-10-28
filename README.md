# CRICIT

Cricket news in one-minute cards, cricket Shorts, and grassroots stories (Nxtspot), with an editorial
dashboard (CRICIT Newsroom).

| Folder | What |
|---|---|
| `backend/` | FastAPI API + ARQ workers (Python 3.12, Postgres 16, Redis 7) |
| `admin/` | Next.js 16 + shadcn/ui newsroom dashboard |
| `mobile/` | Flutter app (Android first) |
| `infra/` | Docker Compose (local + production), Caddy, backup scripts |
| `docs/tickets/` | T01–T40 build tickets; each is a Cursor-sized spec |

## Start in 5 commands

Needs Docker, [uv](https://docs.astral.sh/uv/), Node 20.11+ (Flutter for the app).

```bash
make setup            # install deps, create .env
make keys             # paste the three JWT_* lines into .env
make up               # Postgres, Redis, API (http://localhost:8000/docs), worker
make seed             # owner, sources, 60 cards, ads, Nxtspot examples
make admin            # dashboard on http://localhost:3000
make check            # everything CI runs
```

After `make seed`, sign in to the newsroom as `owner@cricit.app`. Password, TOTP secret and a
recovery code are printed once and saved in `.seed-credentials` (gitignored). Current TOTP:

```bash
python -c "import pyotp; print(pyotp.TOTP('JBSWY3DPEHPK3PXP').now())"
```

Local app login: `POST /v1/auth/firebase` with any `id_token` of at least 20 characters mints a
user session. Staging and production still return `501` until Firebase (T05).

Mobile: see `mobile/README.md` (`flutter create .` once to add the platform folders).

## How to work on it

Read `AGENTS.md`, pick the next ticket in `docs/tickets/`, and follow it. Design rules live in
`DESIGN.md`, product context in `PRODUCT.md`. Cursor loads the rules in `.cursor/rules/` automatically.

## What is real in this stub

Working and tested: settings validation, error format, request IDs, JSON logs with redaction, security
headers, ES256 JWTs with key rotation, refresh-token hashing, Argon2id, TOTP + recovery codes, RBAC and
the deny-by-default route test, the full database schema + first migration, cursor-paginated feed
(integration-tested on Postgres), public search (rate-limited), local user tokens, admin login/TOTP with
lockout, newsroom list APIs (sources, posts, review, ads, audit, Nxtspot, overview), the RSS adapter,
the admin cookie session, every sidebar page with seeded examples, and the Flutter shell.

Still `501 not_implemented`: production Firebase verify (T05), account delete (T31). Not in this MVP:
the LLM ingest pipeline, FCM, AdMob, Fernet TOTP-at-rest, publish/reject writes.
