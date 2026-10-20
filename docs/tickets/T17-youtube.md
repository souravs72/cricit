# T17 — YouTube Shorts ingestion and /v1/videos

**Week:** W5 · **Estimate:** ~4 h · **Depends on:** T09

## Goal

Shorts from configured channels.

## Files

- `api/src/ingestion/youtube.ts`
- `api/src/routes/v1.ts`

## Acceptance

- [ ] playlistItems.list on uploads playlists (1 unit) + videos.list batches of 50
- [ ] Keep ≤ 60 s videos; store id, title, channel, thumbnail only
- [ ] Daily quota tracked in a Durable Object or D1 counter (not KV); stop at 80% of 10,000 units
- [ ] `/v1/videos` cursor-paginated and cacheable
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T17-youtube.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Never download or re-host videos.
