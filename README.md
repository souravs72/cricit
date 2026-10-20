# CRICIT

Cricket news in one-minute cards, cricket Shorts, and grassroots stories (Nxtspot), with an editorial
dashboard (CRICIT Newsroom). Runs entirely on Cloudflare: no servers to manage.

| Folder | What | Runs on |
|---|---|---|
| `api/` | Hono API + ingestion (Cron → Queues → Workflows), TypeScript | Cloudflare Workers, D1, KV, R2 |
| `admin/` | Next.js 16 + shadcn/ui newsroom dashboard | Cloudflare Workers (OpenNext) |
| `mobile/` | Flutter app (Android first) | Play Store |
| `docs/tickets/` | T01–T40 build tickets; each is a Cursor-sized spec | |

## Start in 4 commands

Needs Node 20.11+ (Flutter for the app). No Docker, no database server: Wrangler simulates D1, KV,
Queues and Workflows locally.

```bash
make setup     # install deps, generate local secrets (api/.dev.vars), migrate local D1
make api       # API on http://localhost:8787
make admin     # dashboard on http://localhost:3000 (second terminal)
make check     # everything CI runs
```

Mobile: see `mobile/README.md`.

## Cloudflare resources

| Resource | Staging | Production |
|---|---|---|
| D1 database | `cricit-staging` | `cricit-prod` |
| KV namespace | `cricit-cache-staging` | `cricit-cache-prod` |
| R2 bucket | `cricit-media-staging` | `cricit-media` |
| Queue (+ dead letter) | `cricit-ingest-staging` | `cricit-ingest` |
| Workers | `cricit-api-staging`, `cricit-admin-staging` | `cricit-api`, `cricit-admin` |

D1 and KV already exist (IDs are in the `wrangler.jsonc` files). One-time setup before the first deploy
is ticket T02: Workers Paid plan, enable R2, create the buckets and queues, set secrets.

## How to work on it

Read `AGENTS.md`, pick the next ticket in `docs/tickets/`, and follow it. Design rules live in
`DESIGN.md`, product context in `PRODUCT.md`. Cursor loads the rules in `.cursor/rules/` automatically.

## What is real in this stub

Working and tested inside the Workers runtime (41 tests): config validation, error format, request IDs,
security headers, ES256 JWTs with key rotation, refresh-token hashing, Argon2id, TOTP + recovery codes,
AES-GCM secret encryption, Firebase ID-token verification, RBAC with a deny-by-default route test,
native rate limiting, the full D1 schema + migrations, FTS5 search (English + Hindi), the cursor-paginated
feed with a versioned KV cache, chunked D1 inserts, dedupe and AI-summary validators, and the RSS/Atom
parser. The admin runs as a Worker, reaches the API over a service binding, and checks Origin in every
mutating route handler.

Stubbed with `501 not_implemented` and a ticket number: Firebase exchange and refresh rotation (T05),
admin login/TOTP (T06), sources API (T09), the ingestion steps in `ProcessArticle` (T10–T16), and
everything after.
