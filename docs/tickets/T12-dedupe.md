# T12 — Two-pass dedupe in the Workflow

**Week:** W4 · **Estimate:** ~3 h · **Depends on:** T10

## Goal

Use `src/ingestion/dedupe.ts` verdicts inside ProcessArticle.

## Files

- `api/src/workflows/process-article.ts`
- `api/src/repositories/posts.ts`

## Acceptance

- [ ] Pass 1 before AI: duplicate → post_sources row; possible → continue but mark for review
- [ ] Pass 2 after AI tags: possible → post status `review` with `possible_duplicate_of` set
- [ ] Tests include the 'beat vs lose' and 'different numbers' cases (never auto-merged)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T12-dedupe.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Thresholds were measured: title similarity alone cannot separate rewrites from different stories, so the middle band always goes to an editor.
