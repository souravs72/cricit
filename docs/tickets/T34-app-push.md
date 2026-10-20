# T34 — Push in the app

**Week:** W10 · **Estimate:** ~3 h · **Depends on:** T25,T22

## Goal

Receive and open notifications.

## Files

- `mobile/lib/core/push/*`

## Acceptance

- [ ] Topic opt-ins in settings; tapping a notification opens the card
- [ ] Device token registered with /v1/devices for logged-out users too
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T34-app-push.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
