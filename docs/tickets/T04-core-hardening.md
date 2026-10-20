# T04 — Core: readiness, observability, limits

**Week:** W1 · **Estimate:** ~3 h · **Depends on:** T02

## Goal

Production-safe defaults everywhere before features land.

## Files

- `api/src/core/*`
- `api/src/app.ts`
- `api/test/*`

## Acceptance

- [ ] `/ready` returns 503 with our error JSON when D1 or KV fails (test with a broken binding stub)
- [ ] Workers Logs + Traces enabled (observability already on); one structured log line per request with request_id, status, duration
- [ ] Sentry for Workers (`@sentry/cloudflare`) wraps the handler in staging/production; a thrown error shows up with request_id (screenshot in PR)
- [ ] Test: phone numbers and tokens never appear in logged error output
- [ ] Test: rate-limited request returns 429 with our error shape (mock the RL binding)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T04-core-hardening.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
