# T15 — Image pipeline (R2 + Cloudflare Images)

**Week:** W4 · **Estimate:** ~4 h · **Depends on:** T13

## Goal

Card images follow the agreed image policy and load fast.

## Files

- `api/src/services/images.ts (new)`

## Acceptance

- [ ] Policy switch: `generated` (default) | `licensed` | `publisher`
- [ ] Generated artwork: 5–10 variants per team in R2, no repeat within the last 20 cards (test)
- [ ] Images served through Cloudflare Images transformations (720 px wide, WebP/AVIF) from R2
- [ ] Outbound image fetch has size (5 MB) and content-type limits
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T15-images.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
