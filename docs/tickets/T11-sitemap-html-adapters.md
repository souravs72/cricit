# T11 — Sitemap and HTML adapters

**Week:** W3 · **Estimate:** ~5 h · **Depends on:** T10

## Goal

Read sources without RSS where their terms allow it.

## Files

- `backend/app/ingestion/adapters/sitemap.py`
- `backend/app/ingestion/adapters/html.py`

## Acceptance

- [ ] Sitemap adapter reads news sitemaps and filters to the last 48 h
- [ ] HTML adapter uses CSS selectors from adapter_config (selectolax); fixture tests per configured site
- [ ] robots.txt respected (cached 24 h); polite User-Agent; max 1 request/second per host
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T11-sitemap-html-adapters.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Only sources marked 'use' in docs/sources.md.
