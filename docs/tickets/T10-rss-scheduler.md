# T10 — RSS ingestion and scheduler

**Week:** W3 · **Estimate:** ~5 h · **Depends on:** T09

## Goal

Due sources are fetched on schedule; new items queued for processing.

## Files

- `backend/app/workers/main.py`
- `backend/app/ingestion/*`

## Acceptance

- [ ] `fetch_due_sources` enqueues one job per due source with a job id per source+interval slot (no double runs)
- [ ] ETag/Last-Modified stored on the source; 304 costs no processing
- [ ] Items deduped by url_hash before any further work
- [ ] Failures increment consecutive_failures; 5 in a row pauses the source and records last_error
- [ ] Tests use saved RSS fixtures (no network)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T10-rss-scheduler.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
