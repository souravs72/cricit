# T07 — RBAC enforcement and audit helper

**Week:** W2 · **Estimate:** ~3 h · **Depends on:** T06

## Goal

Permissions enforced in services, every admin write audited.

## Files

- `backend/app/core/permissions.py`
- `backend/app/services/audit.py (new)`

## Acceptance

- [ ] `audit.record(admin_id, action, entity, entity_id, before, after)` helper with a test
- [ ] Changing an admin's role takes effect at their next token refresh (documented + test)
- [ ] Test matrix: for each admin route, viewer/editor/owner get the expected 200/403
- [ ] Deny-by-default route test still passes
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T07-rbac.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
