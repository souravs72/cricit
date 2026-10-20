# T20 — Sources pages with health

**Week:** W6 · **Estimate:** ~3 h · **Depends on:** T09,T18

## Goal

Manage sources in the dashboard.

## Files

- `admin/src/features/sources/*`

## Acceptance

- [ ] List with health (last fetch, failures, paused), create/edit form per adapter type, test-fetch preview
- [ ] Owner/editor only; viewer sees nothing
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T20-sources-pages.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
