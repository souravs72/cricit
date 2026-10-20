# T37 — Backups and restore drill

**Week:** W11 · **Estimate:** ~2 h · **Depends on:** -

## Goal

Data can be recovered.

## Files

- `api/src/workflows/backup.ts (new)`

## Acceptance

- [ ] D1 Time Travel restore rehearsed on staging (`wrangler d1 time-travel restore`), target < 15 min
- [ ] Nightly scheduled Workflow exports D1 to R2 (14-day retention) for disaster recovery beyond 30 days
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T37-backups.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
