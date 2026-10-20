# T10 — Cron → Queue → RSS fetch → Workflow

**Week:** W3 · **Estimate:** ~5 h · **Depends on:** T09

## Goal

Due sources are fetched on schedule and each new item starts one Workflow.

## Files

- `api/src/index.ts`
- `api/src/ingestion/*`
- `api/src/workflows/process-article.ts`

## Acceptance

- [ ] Cron (*/2) selects active sources whose interval elapsed and `sendBatch`es one message each
- [ ] Queue consumer: `fetchRss` with ETag/Last-Modified saved on the source; 304 does no work
- [ ] Each new item: `PROCESS_ARTICLE.create({ id: urlHash, params })`; a duplicate id is caught and skipped
- [ ] Failures increment consecutive_failures; 5 in a row pauses the source with last_error; messages retry with backoff then land in the DLQ
- [ ] Tests use RSS fixtures and Workflow introspection (`introspectWorkflow`) — no network
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T10-ingest-pipeline.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
