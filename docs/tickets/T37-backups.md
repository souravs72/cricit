# T37 — Backups and restore drill

**Week:** W11 · **Estimate:** ~2 h · **Depends on:** -

## Goal

Data can be recovered.

## Files

- `infra/scripts/backup.sh`
- `infra/scripts/restore.sh`

## Acceptance

- [ ] Nightly backup to R2 runs via cron; 14-day retention
- [ ] Timed restore drill documented (target < 30 min)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T37-backups.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
