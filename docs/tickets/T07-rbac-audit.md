# T07 — RBAC enforcement and audit helper

**Week:** W2 · **Estimate:** ~3 h · **Depends on:** T06

## Goal

Permissions enforced, every admin write audited.

## Files

- `api/src/core/permissions.ts`
- `api/src/services/audit.ts (new)`

## Acceptance

- [ ] `audit.record(...)` helper written in the same `db.batch` as the change it records
- [ ] Role change takes effect at the admin's next token refresh (documented + test)
- [ ] Test matrix: for each admin route, viewer/editor/owner get the expected 200/403
- [ ] Deny-by-default route test still passes
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T07-rbac-audit.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
