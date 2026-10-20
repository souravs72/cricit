# T02 — Put the stub on GitHub with green CI

**Week:** W1 · **Estimate:** ~2 h · **Depends on:** -

## Goal

Push this repo to a private GitHub repository with branch protection and passing CI for backend and admin.

## Files

- `.github/workflows/*`
- `README.md`

## Acceptance

- [ ] Private repo created; `main` protected (PR + passing checks required)
- [ ] backend and admin workflows green on main
- [ ] `make setup && make keys && make up` works on a clean clone (follow README literally)
- [ ] Dependabot (or Renovate) enabled for pip, npm, GitHub Actions
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T02-repo-and-ci.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

Mobile CI turns on in T21 once platform folders exist.
