# T32 — Ads in the app

**Week:** W10 · **Estimate:** ~4 h · **Depends on:** T24,T27

## Goal

AdMob + sponsored cards.

## Files

- `mobile/lib/features/ads/*`

## Acceptance

- [ ] AdMob native/footer/interstitial with test IDs in dev; falls back to sponsored card when no fill
- [ ] Impressions/clicks sent via /v1/events
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T32-app-ads.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
