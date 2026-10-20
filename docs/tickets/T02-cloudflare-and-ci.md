# T02 — Cloudflare account setup, GitHub and green CI

**Week:** W1 · **Estimate:** ~3 h · **Depends on:** -

## Goal

Everything needed to deploy exists, and CI guards main.

## Files

- `.github/workflows/*`
- `api/wrangler.jsonc`
- `admin/wrangler.jsonc`

## Acceptance

- [ ] Decide which Cloudflare account owns production (the D1 databases and KV namespaces were created in the account connected during planning; recreate them in the client's account and update the IDs if it must own them)
- [ ] Workers Paid plan active on that account ($5/month; Argon2 and AI steps need more than the free plan's 10 ms CPU)
- [ ] R2 enabled in the dashboard; `wrangler r2 bucket create cricit-media-staging` and `cricit-media`
- [ ] Queues created: `cricit-ingest[-staging]` and `cricit-ingest-dlq[-staging]` (`wrangler queues create ...`)
- [ ] Secrets set for staging and production with `wrangler secret put` (JWT_PRIVATE_KEY, JWT_PUBLIC_KEYS, TOTP_ENCRYPTION_KEY, LLM_API_KEY, YOUTUBE_API_KEY); values from `npm run keys`
- [ ] `npm run db:migrate:staging` applied; `make deploy-staging` succeeds; `/health` and `/ready` return 200 on the staging URL
- [ ] Private GitHub repo; `main` protected (PR + passing checks); CI green; CLOUDFLARE_API_TOKEN stored as a GitHub secret (scoped: Workers, D1, KV, R2, Queues)
- [ ] Dependabot (or Renovate) enabled for npm and GitHub Actions
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T02-cloudflare-and-ci.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

The D1 databases and KV namespaces already exist (IDs in wrangler.jsonc). Mobile CI turns on in T21.
