# T06 — Admin auth: invite, password, TOTP, lockout

**Week:** W2 · **Estimate:** ~6 h · **Depends on:** T03,T04

## Goal

Owner-invited admins sign in with email + password + TOTP.

## Files

- `backend/app/services/admin_auth.py (new)`
- `backend/app/api/admin/routes.py`
- `backend/scripts/create_owner.py (new)`

## Acceptance

- [ ] `create_owner.py` creates the first owner with an invite link (only works when no owner exists)
- [ ] Invite accept: sets password (≥12 chars, rejected if in breached list file), enrolls TOTP (returns otpauth URI + 10 recovery codes shown once)
- [ ] Login step 1 returns a short-lived challenge (Redis, 5 min); step 2 accepts TOTP or an unused recovery code
- [ ] 5 failed attempts lock the account 15 minutes; same error text for unknown email and wrong password (test)
- [ ] Admin access token carries `perms` from the role; 10-minute lifetime; session idle 30 min / absolute 12 h
- [ ] TOTP secrets encrypted at rest (Fernet key from env) — test that DB value is not the plain secret
- [ ] Every auth event written to audit_log
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T06-admin-auth.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
