# T05 — App user auth: Firebase exchange and refresh rotation

**Week:** W2 · **Estimate:** ~6 h · **Depends on:** T03,T04

## Goal

Implement `/v1/auth/firebase`, `/v1/auth/refresh`, `/v1/auth/logout` exactly as the plan's auth section describes.

## Files

- `backend/app/services/auth.py (new)`
- `backend/app/repositories/sessions.py (new)`
- `backend/app/api/v1/routes.py`
- `backend/app/core/auth.py`

## Acceptance

- [ ] Firebase ID token verified with firebase-admin: signature, aud, iss, auth_time < 5 min old (mock the verifier in tests)
- [ ] User upserted by firebase_uid; phone stored; returns access (15 min) + refresh token
- [ ] Refresh rotates: old token stops working, new pair returned
- [ ] Reusing an already-rotated refresh token revokes the whole family; both old and new refresh tokens then fail (test)
- [ ] Logout revokes the session; its access token is rejected within 60 s (Redis revocation list keyed by sid with TTL = token lifetime)
- [ ] Sliding 30-day and absolute 90-day expiry enforced (test with frozen time)
- [ ] Rate limit: 10 exchanges/hour per device_id
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T05-user-auth.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Do not trust any user field from the request body. Never log tokens.
