# T28 — Category tabs, card actions, deep links

**Week:** W8 · **Estimate:** ~4 h · **Depends on:** T27

## Goal

Tabs, share, open source, deep links.

## Files

- `mobile/lib/features/feed/*`
- `mobile/lib/app/router.dart`

## Acceptance

- [ ] Domestic/International/Nxtspot tabs; source opens in in-app browser
- [ ] Share uses share_url; cricit.app/p/{id} opens that card (Android App Links; assetlinks.json served by a Worker)
- [ ] Team edge strip shows for tagged cards
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T28-tabs-and-cards.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
