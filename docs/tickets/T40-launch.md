# T40 — Production release and handover

**Week:** W12 · **Estimate:** ~4 h · **Depends on:** T39

## Goal

Launch and hand over.

## Files

- `docs/runbook.md (new)`

## Acceptance

- [ ] Production release live; Workers Logs, alerts and dashboards on
- [ ] Runbook: deploy, rollback (`wrangler rollback`), rotate keys, D1 restore, add a source, add an admin
- [ ] Handover call with the client; maintenance retainer agreed
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T40-launch.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
