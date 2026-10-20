# T16 — Publish flow and feed interleaving

**Week:** W5 · **Estimate:** ~5 h · **Depends on:** T13

## Goal

Publishing is instant for readers and the feed mixes in Nxtspot and ads.

## Files

- `api/src/services/feed.ts`
- `api/src/services/publish.ts (new)`

## Acceptance

- [ ] Publish writes the post then calls `bumpFeedVersion` (cache invalidation already tested)
- [ ] Nxtspot card every 8 and ad slot every 6 in the `feed` tab (settings-driven, test)
- [ ] Feed p95 < 150 ms on a KV miss with 10k posts on staging (note in PR)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T16-publish-feed.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
