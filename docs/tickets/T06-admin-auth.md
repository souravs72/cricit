# T06 — Admin auth: invite, password, TOTP, lockout

**Week:** W2 · **Estimate:** ~6 h · **Depends on:** T03,T04

## Goal

Owner-invited admins sign in with email + password + TOTP.

## Files

- `api/src/services/admin-auth.ts (new)`
- `api/src/routes/admin.ts`
- `api/scripts/create-owner.ts (new)`

## Acceptance

- [ ] `create-owner` makes the first owner and prints a one-time invite link (only works when no owner exists)
- [ ] Invite accept: password ≥12 chars and not in a breached-password list; Argon2id via core/security.ts; TOTP enrolment returns otpauth URI + 10 recovery codes shown once
- [ ] TOTP secret stored only encrypted (`encryptSecret`); test that the DB value is not the plain secret
- [ ] Login step 1 returns a 5-minute challenge (KV); step 2 accepts TOTP or an unused recovery code
- [ ] 5 failures lock the account 15 minutes; same error text for unknown email and wrong password (test)
- [ ] Admin access token carries `perms` from the role; 10-minute lifetime; idle 30 min / absolute 12 h
- [ ] Every auth event written to audit_log
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T06-admin-auth.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
