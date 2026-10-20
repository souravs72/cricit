# T13 — Text extraction, LLM via AI Gateway, validation, cost

**Week:** W4 · **Estimate:** ~6 h · **Depends on:** T12

## Goal

Turn an article into a validated card.

## Files

- `api/src/ai/*`
- `api/src/workflows/process-article.ts`

## Acceptance

- [ ] Extraction with HTMLRewriter (article/main/p text) in memory only; full text never stored
- [ ] LLM adapter calls the provider through Cloudflare AI Gateway (logs, caching, retries, fallback model)
- [ ] `validateSummary` + relevance ≥ 0.5 required to auto-publish (trusted sources); else status `review`
- [ ] ai_jobs row per call with tokens and cost; invalid JSON → one repair attempt → review
- [ ] Tests with a fake LLMClient
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T13-llm-summaries.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
