# T13 — LLM client, summarize_v1, validators, cost tracking

**Week:** W4 · **Estimate:** ~6 h · **Depends on:** T12

## Goal

Turn extracted article text into a validated card.

## Files

- `backend/app/ai/*`
- `backend/app/services/ingest.py`

## Acceptance

- [ ] Provider adapter implements `LLMClient.complete_json` with JSON-schema output and timeouts
- [ ] trafilatura extracts text in memory only; full text never stored
- [ ] `validate_summary` + relevance ≥ 0.5 required to auto-publish (trusted sources); otherwise `review`
- [ ] ai_jobs row per call with tokens and cost; daily cost visible via a service method
- [ ] Retries: 2 on timeout/5xx; invalid JSON → one repair attempt → review
- [ ] Tests with a fake LLM client
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T13-llm-summaries.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
