# T26 — Analytics with Workers Analytics Engine

**Week:** W7 · **Estimate:** ~4 h · **Depends on:** T16,T18

## Goal

Real numbers on the overview scoreboard.

## Files

- `api analytics service`
- `admin overview + analytics pages`

## Acceptance

- [ ] `/v1/events` writes data points to Analytics Engine (max 100 events/call, rate-limited per device)
- [ ] Daily Cron rolls up into post_stats_daily/ad_stats_daily via the Analytics Engine SQL API (idempotent upsert)
- [ ] Overview scoreboard and analytics pages read the rollups; no raw event rows in D1
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T26-analytics.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
