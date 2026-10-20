# T03 — Finish models, migrations and seed data

**Week:** W1 · **Estimate:** ~4 h · **Depends on:** T02

## Goal

The schema matches the system design; a seed script creates realistic local data.

## Files

- `backend/app/models/*`
- `backend/alembic/versions/*`
- `backend/scripts/seed.py (new)`

## Acceptance

- [ ] `make migrate` on an empty DB creates every table; `alembic check` reports no drift
- [ ] `uv run python scripts/seed.py` creates 1 owner admin (prints a one-time password), 5 sources, 60 published posts across categories with Hindi text, 2 ad campaigns
- [ ] Seed is idempotent (running twice does not duplicate)
- [ ] Integration test: feed returns seeded posts newest first
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T03-models-and-seed.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Keep TOTP secret encryption for T06.
