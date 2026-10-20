# ADR 0002: Run everything on Cloudflare

**Status:** accepted · **Date:** 2026-10-20 · **Supersedes:** the hosting and backend parts of ADR 0001

## Decision

API on Cloudflare Workers (Hono, TypeScript), data in D1, cache in KV, media in R2, ingestion as
Cron → Queues → Workflows, admin (Next.js 16) on Workers through OpenNext, reaching the API over a
service binding. No servers.

## Why

- Requested by the client lead: one platform, no servers to patch, scales without code changes.
- Cost at MVP scale: Workers Paid ($5/month) covers requests, CPU, D1, KV, Queues and Workflows quotas.
- Reliability: Workflows give durable, per-step retries for ingestion; D1 Time Travel gives 30-day
  point-in-time restore.

## Choices inside the decision

| Choice | Picked | Rejected and why |
|---|---|---|
| Language | TypeScript | Python Workers: FastAPI support only since Sep 2026; C-extension packages don't run |
| Database | D1 | Postgres via Hyperdrive: another vendor; D1 limits (10 GB/db) fit a 30-day feed |
| Next.js adapter | OpenNext (stable) | vinext: Cloudflare's recommended path for new apps but still beta |
| Password hashing | Argon2id, pure JS (@noble/hashes, ~300 ms) | hash-wasm: Workers forbid runtime WebAssembly compilation |
| Counters | Analytics Engine / Durable Objects | KV: eventually consistent, wrong for counts and caps |

## Consequences

- No Node-runtime middleware in the admin: auth and CSRF checks live in route handlers and the layout.
- D1 allows 100 bound parameters per statement: bulk writes go through `insertMany`.
- Errors are always `Cache-Control: no-store` so the edge never caches a failure.
