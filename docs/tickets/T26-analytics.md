# T26 — Analytics counters and overview

**Week:** W7 · **Estimate:** ~4 h · **Depends on:** T16,T18

## Goal

Real numbers on the overview scoreboard.

## Files

- `backend events + rollup job`
- `admin overview + analytics pages`

## Acceptance

- [ ] `/v1/events` increments Redis counters (max 100 events/call, per-device rate limit)
- [ ] Hourly rollup into post_stats_daily/ad_stats_daily is idempotent (test)
- [ ] Overview scoreboard and analytics charts read the rollups; no raw event rows stored
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T26-analytics.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
