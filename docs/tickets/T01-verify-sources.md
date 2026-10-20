# T01 — Verify every news and video source

**Week:** W1 · **Estimate:** ~4 h · **Depends on:** -

## Goal

Confirm how each source in the brief can be read (RSS, sitemap or HTML), and whether its terms allow automated access. The client signs the final list.

## Files

- `docs/sources.md (new): one row per source`

## Acceptance

- [ ] Every source from the brief is listed: BCCI, ICC, IPL, Cricbuzz, ESPNcricinfo, Sportskeeda, Fox Sports, BBC, TOI, NDTV, plus each YouTube channel
- [ ] Each row has: adapter (rss/sitemap/html/none), feed URL or listing URL, robots.txt result, terms-of-use note, decision (use/drop)
- [ ] YouTube channels have their channel ID and uploads playlist ID
- [ ] Client has replied 'approved' on the list (save the email/message reference)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T01-verify-sources.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Do not write scrapers yet. A source whose terms forbid automated access is dropped, not worked around.
