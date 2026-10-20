# T12 — Two-pass dedupe wired into the pipeline

**Week:** W4 · **Estimate:** ~3 h · **Depends on:** T10

## Goal

Use `app/ingestion/dedupe.py` verdicts in the pipeline.

## Files

- `backend/app/services/ingest.py (new)`

## Acceptance

- [ ] DUPLICATE → added to post_sources of the existing post
- [ ] POSSIBLE → post created with status `review` and a `possible_duplicate_of` link shown in the review queue
- [ ] DISTINCT → continues
- [ ] Tests include the 'beat vs lose' and 'different numbers' cases (never auto-merged)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T12-dedupe.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Thresholds were measured: title similarity alone cannot separate same-story rewrites from different stories, so the middle band always goes to an editor.
