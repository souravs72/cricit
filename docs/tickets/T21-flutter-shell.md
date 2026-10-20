# T21 — Flutter shell, flavors, CI

**Week:** W6 · **Estimate:** ~4 h · **Depends on:** T02

## Goal

The app builds for dev/staging/prod.

## Files

- `mobile/*`
- `.github/workflows/mobile.yml`

## Acceptance

- [ ] `flutter create .` run; Android min SDK 23; flavors dev/staging/prod with separate app IDs
- [ ] API base URL and flavor via --dart-define (dev → wrangler dev on :8787)
- [ ] Mobile CI green; release signing documented (keystore not in git)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T21-flutter-shell.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
