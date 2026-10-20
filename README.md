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
make admin            # dashboard on http://localhost:3000
make check            # everything CI runs
```

Mobile: see `mobile/README.md` (`flutter create .` once to add the platform folders).

## How to work on it

Read `AGENTS.md`, pick the next ticket in `docs/tickets/`, and follow it. Design rules live in
`DESIGN.md`, product context in `PRODUCT.md`. Cursor loads the rules in `.cursor/rules/` automatically.

## What is real in this stub

Working and tested: settings validation, error format, request IDs, JSON logs with redaction, security
headers, ES256 JWTs with key rotation, refresh-token hashing, Argon2id, TOTP + recovery codes, RBAC and
the deny-by-default route test, the full database schema + first migration, cursor-paginated feed
(integration-tested on Postgres), dedupe and AI-summary validators, the RSS adapter, the admin's cookie
session plumbing, proxy, CSRF origin check, login and overview screens, and the Flutter shell with the
auth interceptor and card view.

Stubbed with `501 not_implemented` and a ticket number: Firebase exchange and refresh rotation (T05),
admin login/TOTP (T06), sources API (T09), and everything after.
