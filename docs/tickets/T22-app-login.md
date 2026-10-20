# T22 — Phone OTP onboarding

**Week:** W7 · **Estimate:** ~5 h · **Depends on:** T05,T21

## Goal

Readers can sign in with their phone or skip.

## Files

- `mobile/lib/features/auth/*`

## Acceptance

- [ ] Firebase phone auth + App Check; exchange with `/v1/auth/firebase`; tokens in TokenStore
- [ ] Skip allowed; bookmark/submit prompt sign-in later
- [ ] Error states for wrong OTP, too many attempts, offline
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T22-app-login.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
