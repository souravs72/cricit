# T04 — Core: settings, errors, logging, health

**Week:** W1 · **Estimate:** ~3 h · **Depends on:** T02

## Goal

Production-safe defaults everywhere before features land.

## Files

- `backend/app/core/*`
- `backend/app/main.py`
- `backend/tests/*`

## Acceptance

- [ ] /ready returns 503 with a JSON error when Postgres or Redis is down (test with a bad URL)
- [ ] Rate-limit helper in `app/core/ratelimit.py` (Redis sliding window) with unit tests
- [ ] Request body size capped (1 MB) at the app level
- [ ] Sentry captures an unhandled exception with request_id tag (manual check, screenshot in PR)
- [ ] Log redaction test: phone numbers and tokens never appear in log output
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T04-core-hardening.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
