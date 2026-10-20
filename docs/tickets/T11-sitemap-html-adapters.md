# T11 — Sitemap and HTML adapters (HTMLRewriter)

**Week:** W3 · **Estimate:** ~5 h · **Depends on:** T10

## Goal

Read sources without RSS where their terms allow it.

## Files

- `api/src/ingestion/sitemap.ts`
- `api/src/ingestion/html.ts`

## Acceptance

- [ ] Sitemap adapter reads news sitemaps, last 48 h only
- [ ] HTML adapter uses HTMLRewriter with selectors from adapter_config; fixture tests per configured site
- [ ] robots.txt respected (cached 24 h in KV); polite User-Agent; ≤1 request/second per host
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T11-sitemap-html-adapters.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Only sources marked 'use' in docs/sources.md.
