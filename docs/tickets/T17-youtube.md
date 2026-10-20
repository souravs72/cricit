# T17 — YouTube Shorts ingestion and /v1/videos

**Week:** W5 · **Estimate:** ~4 h · **Depends on:** T09

## Goal

Shorts from configured channels.

## Files

- `backend/app/ingestion/youtube.py`
- `backend/app/api/v1/routes.py`

## Acceptance

- [ ] Uses playlistItems.list on uploads playlists (1 unit) + videos.list in batches of 50
- [ ] Keeps videos ≤ 60 s; stores id, title, channel, thumbnail only
- [ ] Daily quota usage tracked in Redis; stops at 80% of 10,000 units
- [ ] `/v1/videos` cursor-paginated, CDN cacheable
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T17-youtube.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Never download or re-host videos.
