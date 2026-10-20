# T05 — App user auth: Firebase exchange and refresh rotation

**Week:** W2 · **Estimate:** ~6 h · **Depends on:** T03,T04

## Goal

Implement `/v1/auth/firebase`, `/v1/auth/refresh`, `/v1/auth/logout` exactly as the plan's auth section describes.

## Files

- `api/src/services/auth.ts (new)`
- `api/src/repositories/sessions.ts (new)`
- `api/src/routes/v1.ts`
- `api/src/core/auth.ts`

## Acceptance

- [ ] `verifyFirebaseIdToken` (already in core/firebase.ts) is used; tests sign tokens with a local key
- [ ] User upserted by firebase_uid; phone stored; returns access (15 min) + refresh token
- [ ] Refresh rotates: old token stops working, new pair returned (D1 `sessions`, write + revoke in one `db.batch`)
- [ ] Reusing an already-rotated refresh token revokes the whole family; both old and new refresh tokens then fail (test)
- [ ] Logout revokes the session; auth middleware rejects its access token via a KV revocation entry keyed by sid (TTL = token lifetime)
- [ ] Sliding 30-day and absolute 90-day expiry enforced (test with injected time)
- [ ] Rate limit RL_AUTH applies (10/min per IP+device)
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T05-user-auth.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Do not trust any user field from the request body. Never log tokens.
