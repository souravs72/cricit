# T16 — Publish flow, feed cache, interleaving

**Week:** W5 · **Estimate:** ~5 h · **Depends on:** T13

## Goal

Fast public feed served from cache.

## Files

- `backend/app/services/feed.py`
- `backend/app/services/publish.py (new)`

## Acceptance

- [ ] Publishing a post rebuilds Redis JSON for the first 3 pages of affected tabs × languages
- [ ] Nxtspot card every 8 cards and ad slot every 6 in the `feed` tab (settings-driven)
- [ ] Feed p95 < 150 ms on cache miss with 10k posts (pytest-benchmark or k6 note in PR)
- [ ] Cache-Control headers verified by test
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T16-feed-cache.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
