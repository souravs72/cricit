# T19 — Review queue and posts table

**Week:** W6 · **Estimate:** ~6 h · **Depends on:** T16,T18

## Goal

Editors approve, edit and publish cards.

## Files

- `admin/src/features/posts/*`
- `api posts admin routes`

## Acceptance

- [ ] Review queue shows the AI card beside the original link; approve / edit / reject with keyboard shortcuts
- [ ] Possible duplicates show the existing post side by side
- [ ] Posts table: server-side filters, cursor pagination, pin, unpublish, regenerate
- [ ] All actions audited; optimistic UI rolls back on error
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T19-review-and-posts.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
