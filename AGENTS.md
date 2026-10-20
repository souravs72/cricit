# AGENTS.md — read this before writing any code

CRICIT is an Inshorts-style cricket news app: AI turns cricket articles into 60-word cards, aggregates
YouTube Shorts, and runs a grassroots section (Nxtspot). Everything runs on Cloudflare.

| Folder | What | Run checks |
|---|---|---|
| `api/` | Hono API on Workers + D1, KV, R2, Queues, Workflows, Cron | `make check-api` |
| `admin/` | Next.js 16 newsroom (shadcn/ui) on Workers via OpenNext | `make check-admin` |
| `mobile/` | Flutter app (Riverpod, go_router, Dio) | `make check-mobile` |

Plan and tickets: `docs/tickets/T01…T40`. Work on **one ticket at a time**. The ticket file is the spec.

## Workflow for every ticket

1. Read the ticket, this file, and the matching `.cursor/rules/*.mdc`.
2. For tickets over ~3 hours, write a short plan first and wait for approval.
3. Write tests first (they should fail), then the code.
4. Run `make check` (or the app-specific target). It must pass before you say you're done.
5. Summarise what changed and how you verified it. Never claim a check passed without running it.

## Architecture rules (api)

- Layers: `routes/` → `services/` → `repositories/` → `db/schema.ts`. A layer only calls the one below.
- **All SQL lives in `repositories/`** (Drizzle). Routes contain no business logic.
- Every route declares exactly one auth middleware from `src/core/auth.ts`
  (`publicRoute`, `optionalUser`, `currentUser`, `currentAdmin`, `requirePermission(p)`).
  `test/route-auth.test.ts` fails the build otherwise.
- `user_id` always comes from the token (`claimsOf(c).sub`), **never** from the request body or query.
- Errors: throw `AppError` subclasses from `src/core/errors.ts`. Errors are always `Cache-Control: no-store`.
- Validate every input with zod via `zValidator(..., validationHook)`.
- Every admin write goes through a service that writes `audit_log`.
- Background work is Cron → Queue → Workflow. Workflow steps are idempotent; instance ids are natural
  keys (e.g. the URL hash) so duplicates are rejected by the platform.
- **Workers runtime limits that bite:** no runtime WebAssembly compilation (use pure-JS or statically
  imported `.wasm`), D1 allows **100 bound parameters per statement** (use `insertMany` in
  `src/db/batch.ts`), 128 MB memory, outbound `fetch` needs `AbortSignal.timeout(...)`.
- Schema changes: edit `src/db/schema.ts` → `make migration m=what_changed` → read the SQL → apply.
  Never edit an applied migration. FTS and triggers live in hand-written migrations.
- Times are epoch milliseconds (UTC) in D1; convert to IST only in clients.
- Secrets only via `wrangler secret put` / `.dev.vars`. Declare new ones in `src/secrets.d.ts` and
  `src/core/config.ts`. Run `npm run types` after changing `wrangler.jsonc`.

## Architecture rules (admin)

- The browser **never** sees a token. Tokens live in `__Host-` HttpOnly cookies set by route handlers;
  server code calls the API through `lib/api/server.ts` (service binding on Cloudflare); client code
  calls `/api/proxy/*`.
- **No middleware/proxy.ts.** OpenNext cannot run Node-runtime middleware. Auth is checked by the
  dashboard layout (API returns 401 → redirect) and every mutating route handler starts with
  `rejectCrossSite(req)`.
- No `NEXT_PUBLIC_` secrets. Server-only modules import `"server-only"`.
- Types come from `npm run gen:api` (API OpenAPI, added in T09). Don't hand-write API types.
- UI components come from `src/components/ui` (shadcn), themed by `DESIGN.md` tokens.

## Architecture rules (mobile)

- Feature-first: `lib/features/<feature>/{data,domain,presentation}`.
- One Dio client (`core/api/api_client.dart`); never create another.
- Tokens only in `flutter_secure_storage`.

## Never

- Commit secrets, `.dev.vars`, keys, or real phone numbers. Log tokens, OTPs or phone numbers.
- Disable a test, lint rule or type check to make a build pass.
- Store full article text (only our AI summary, headline, credit and link).
- Download or re-host YouTube videos (official embedded player only).
- Add a dependency without saying why in the PR, or one that needs Node-only APIs/native modules in `api/`.
- Hide a button and call it authorization. The API enforces permissions.

## Design

`DESIGN.md` is the design source of truth (tokens, type, layout, principles) and `PRODUCT.md` the product
context; both follow gstack's format, so `/design-review` and `/plan-design-review` in Claude Code read them.
