# T36 — Security pass

**Week:** W11 · **Estimate:** ~4 h · **Depends on:** all

## Goal

Close every item on the hardening checklist.

## Files

- *

## Acceptance

- [ ] Hardening checklist in the plan: every item ticked with evidence
- [ ] `npm audit --omit=dev` clean (api + admin) or accepted with reason
- [ ] Cloudflare WAF managed rules on for the custom domains; OWASP ZAP baseline on the admin: no high findings
- [ ] In Claude Code, run gstack /cso and fix findings
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T36-security-pass.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.
