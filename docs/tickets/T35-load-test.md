# T35 — Load test

**Week:** W11 · **Estimate:** ~3 h · **Depends on:** T16

## Goal

Prove the single VPS holds.

## Files

- `infra/k6/feed.js (new)`

## Acceptance

- [ ] 500 req/s on cache-miss feed path for 5 minutes with p95 < 300 ms and 0 errors on the staging VPS
- [ ] Results and bottlenecks written to docs/adr/0003-load-test.md
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T35-load-test.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
