# T24 — Ads: campaigns, slots, caps

**Week:** W7 · **Estimate:** ~5 h · **Depends on:** T16,T18

## Goal

Direct-sold ads managed in the newsroom.

## Files

- `backend ads service`
- `admin/src/features/ads/*`

## Acceptance

- [ ] Campaign CRUD (owner only), creative upload via signed R2 URL, schedule, frequency, daily cap
- [ ] Feed inserts sponsored cards and full-page slots per rules; caps enforced via Redis counters
- [ ] Video tab has no ads (YouTube policy)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T24-ads.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
