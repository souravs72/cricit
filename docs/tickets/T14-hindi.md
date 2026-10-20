# T14 — Hindi headline and summary

**Week:** W4 · **Estimate:** ~2 h · **Depends on:** T13

## Goal

Hindi text produced in the same LLM call and validated.

## Files

- `backend/app/ai/*`

## Acceptance

- [ ] `looks_hindi` passes for headline_hi and summary_hi, else Hindi fields left empty (English shown)
- [ ] Feed with `lang=hi` falls back to English per card when Hindi is missing (test)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T14-hindi.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
