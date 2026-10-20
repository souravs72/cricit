# T30 — Search and discover

**Week:** W9 · **Estimate:** ~4 h · **Depends on:** T16,T21

## Goal

Find stories and browse Nxtspot.

## Files

- `mobile/lib/features/search/*`
- `backend /v1/search, /v1/discover`

## Acceptance

- [ ] Debounced search (300 ms); results open as swipeable cards
- [ ] Backend search rate-limited 30/min per IP, Redis-cached (not CDN)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T30-search.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
