# T30 — Search and discover in the app

**Week:** W9 · **Estimate:** ~4 h · **Depends on:** T21

## Goal

Find stories and browse Nxtspot.

## Files

- `mobile/lib/features/search/*`
- `api /v1/discover`

## Acceptance

- [ ] Debounced search (300 ms) against `/v1/search` (FTS5, already built); results open as swipeable cards
- [ ] `/v1/discover`: trending + Nxtspot rails, cacheable
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T30-search-discover.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
