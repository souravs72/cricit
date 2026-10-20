# T25 — Push notifications (FCM HTTP v1)

**Week:** W7 · **Estimate:** ~4 h · **Depends on:** T18

## Goal

Breaking news alerts with sensible limits.

## Files

- `api push service`
- `admin/src/features/push/*`

## Acceptance

- [ ] FCM HTTP v1 from the Worker (service-account JWT signed with Web Crypto); topics per category and language
- [ ] Max 4/day, never two within 60 min, quiet hours 22:00–07:00 IST (tests)
- [ ] Idempotency key prevents double sends
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T25-push.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
