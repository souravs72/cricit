# T31 — Profile, bookmarks, settings, account delete

**Week:** W9 · **Estimate:** ~5 h · **Depends on:** T22

## Goal

Everything on the profile tab.

## Files

- `mobile/lib/features/profile/*`
- `backend /v1/me*`

## Acceptance

- [ ] Bookmarks sync with the backend; settings: language, notifications, night mode, text size, autoplay
- [ ] Account delete: confirmation, revokes all sessions, data purged after 30 days (Play policy)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T31-profile.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
