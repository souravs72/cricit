# T09 — Sources admin API + OpenAPI

**Week:** W3 · **Estimate:** ~4 h · **Depends on:** T07

## Goal

CRUD for sources plus a dry-run fetch; publish an OpenAPI document for the admin's types.

## Files

- `api/src/routes/admin.ts`
- `api/src/services/sources.ts`
- `api/src/repositories/sources.ts`

## Acceptance

- [ ] List/create/update/pause; `sources:manage` required; audited
- [ ] `POST /admin/v1/sources/{id}/test` runs the adapter and returns the first 10 items without saving
- [ ] adapter_config validated per adapter type (zod discriminated union)
- [ ] URLs restricted to public https hosts (no IPs, no localhost) — SSRF test
- [ ] `/openapi.json` served (hono-openapi or @hono/zod-openapi); admin `npm run gen:api` works
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T09-sources-api.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
