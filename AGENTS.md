# AGENTS.md — read this before writing any code

CRICIT is an Inshorts-style cricket news app: AI turns cricket articles into 60-word cards, aggregates
YouTube Shorts, and runs a grassroots section (Nxtspot). Three apps in one repo:

| Folder | What | Run checks |
|---|---|---|
| `backend/` | FastAPI API + ARQ workers, Postgres, Redis | `make check-backend` |
| `admin/` | Next.js 16 newsroom dashboard (shadcn/ui) | `make check-admin` |
| `mobile/` | Flutter app (Riverpod, go_router, Dio) | `make check-mobile` |

Plan and tickets: `docs/tickets/T01…T40`. Work on **one ticket at a time**. The ticket file is the spec.

## Workflow for every ticket

1. Read the ticket, this file, and the matching `.cursor/rules/*.mdc`.
2. For tickets over ~3 hours, write a short plan first and wait for approval.
3. Write tests first (they should fail), then the code.
4. Run `make check` (or the app-specific target). It must pass before you say you're done.
5. Summarise what changed and how you verified it. Never claim a check passed without running it.

## Architecture rules (backend)

- Layers: `api/` routers → `services/` → `repositories/` → `models/`. A layer only calls the one below.
- **All SQL lives in `repositories/`.** Routers contain no business logic.
- Every route declares exactly one auth dependency from `app/core/auth.py`
  (`public`, `optional_user`, `current_user`, `current_admin`, `require(Permission.X)`).
  `tests/test_route_auth.py` fails the build otherwise.
- `user_id` always comes from the token (`claims.sub`), **never** from the request body or query.
- Errors: raise `AppError` subclasses from `app/core/errors.py`. Never return raw exception text.
- Every admin write goes through a service that writes `audit_log`.
- Background jobs are idempotent and safe to retry.
- Schema changes: edit models, then `make migration m="what changed"`, review the generated file.
- Timestamps are UTC (`timestamptz`); convert to IST only in clients.
- Outbound HTTP always has timeouts. No `requests`; use `httpx.AsyncClient`.

## Architecture rules (admin)

- The browser **never** sees a token. Tokens live in `__Host-` HttpOnly cookies set by route handlers;
  server code calls the backend through `lib/api/server.ts`; client code calls `/api/proxy/*`.
- No `NEXT_PUBLIC_` secrets. Server-only modules import `"server-only"`.
- Types come from `npm run gen:api` (backend OpenAPI). Don't hand-write API types.
- UI components come from `src/components/ui` (shadcn), themed by `DESIGN.md` tokens.

## Architecture rules (mobile)

- Feature-first: `lib/features/<feature>/{data,domain,presentation}`.
- One Dio client (`core/api/api_client.dart`); never create another.
- Tokens only in `flutter_secure_storage`.

## Never

- Commit secrets, `.env`, keys, or real phone numbers. Log tokens, OTPs or phone numbers.
- Disable a test, lint rule or type check to make a build pass.
- Store full article text (only our AI summary, headline, credit and link).
- Download or re-host YouTube videos (official embedded player only).
- Add a dependency without saying why in the PR.
- Hide a button and call it authorization. The backend enforces permissions.

## Design

`DESIGN.md` is the design source of truth (tokens, type, layout, principles) and `PRODUCT.md` the product
context; both follow gstack's format, so `/design-review` and `/plan-design-review` in Claude Code read them.
