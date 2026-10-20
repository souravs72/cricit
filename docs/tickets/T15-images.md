# T15 — Image pipeline

**Week:** W4 · **Estimate:** ~4 h · **Depends on:** T13

## Goal

Card images follow the image policy agreed with the client.

## Files

- `backend/app/services/images.py (new)`

## Acceptance

- [ ] Policy switch from settings: `generated` (default) | `licensed` | `publisher`
- [ ] Generated artwork: 5–10 variants per team, no repeat within the last 20 cards (test)
- [ ] Images converted to WebP, max 720 px wide, < 60 KB target, uploaded to R2 with content hash names
- [ ] Outbound image fetch has size (5 MB) and type limits
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T15-images.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
