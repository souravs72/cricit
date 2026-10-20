# T18 — Admin shell: login, 2FA, session refresh

**Week:** W5 · **Estimate:** ~5 h · **Depends on:** T06

## Goal

Admins can sign in and move around the newsroom.

## Files

- `admin/src/app/(auth)/*`
- `admin/src/app/(dashboard)/layout.tsx`
- `admin/src/lib/*`

## Acceptance

- [ ] Login → TOTP → overview works against the real API (local and staging)
- [ ] Expired access token refreshed silently once (single-flight) in `apiFetch`; failure → /login
- [ ] Logout revokes the API session then clears cookies
- [ ] Playwright smoke: login → overview, against `npm run preview` (the Worker build)
- [ ] Visual check against DESIGN.md (screenshot in PR)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T18-admin-shell.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
