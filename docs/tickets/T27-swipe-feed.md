# T27 — Swipe feed with offline cache

**Week:** W8 · **Estimate:** ~6 h · **Depends on:** T16,T21

## Goal

The core reading experience.

## Files

- `mobile/lib/features/feed/*`

## Acceptance

- [ ] Vertical PageView; next 3 images pre-cached; cursor pagination when 5 cards from the end
- [ ] Drift cache: last 50 cards per tab shown instantly offline
- [ ] 'New posts' pill on refresh instead of jumping the feed
- [ ] Golden test for NewsCardView in light and dark
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T27-swipe-feed.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
