# T03 — Finish schema, migrations and seed data

**Week:** W1 · **Estimate:** ~4 h · **Depends on:** T02

## Goal

The D1 schema matches the system design; a seed script creates realistic local data.

## Files

- `api/src/db/schema.ts`
- `api/migrations/*`
- `api/scripts/seed.ts (new)`

## Acceptance

- [ ] `make migrate-local` on an empty DB creates every table and the FTS index
- [ ] Seed (run with `wrangler d1 execute --local --file` or a seed Worker route behind `ENV=local`) creates 1 owner admin invite, 5 sources, 60 published posts across categories with Hindi text, 2 ad campaigns
- [ ] Seed is idempotent (running twice does not duplicate); uses `insertMany` for bulk rows
- [ ] Integration test: feed returns seeded posts newest first
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T03-schema-and-seed.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
