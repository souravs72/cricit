# T09 — Sources admin API

**Week:** W3 · **Estimate:** ~4 h · **Depends on:** T07

## Goal

CRUD for sources plus a dry-run fetch.

## Files

- `backend/app/api/admin/routes.py`
- `backend/app/services/sources.py`
- `backend/app/repositories/sources.py`
- `backend/app/schemas/sources.py`

## Acceptance

- [ ] List/create/update/pause sources; `sources:manage` required; audited
- [ ] `POST /admin/v1/sources/{id}/test` fetches with the adapter and returns the first 10 items without saving
- [ ] adapter_config validated per adapter type (Pydantic discriminated union)
- [ ] URLs restricted to http(s) public hosts (no localhost/private IPs — SSRF test)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T09-sources-api.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
