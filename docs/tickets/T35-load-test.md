# T35 — Load test

**Week:** W11 · **Estimate:** ~3 h · **Depends on:** T16

## Goal

Prove the read path holds.

## Files

- `infra/k6/feed.js (new)`

## Acceptance

- [ ] 500 req/s on the KV-miss feed path for 5 minutes on staging: p95 < 300 ms, 0 errors
- [ ] Results and D1 read metrics written to docs/adr/0004-load-test.md
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T35-load-test.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
