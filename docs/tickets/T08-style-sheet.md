# T08 — Client approves the visual style sheet; scope freeze

**Week:** W2 · **Estimate:** ~3 h · **Depends on:** -

## Goal

Lock the look and scope before UI work starts.

## Files

- `DESIGN.md`
- `docs/style-sheet.html (new)`

## Acceptance

- [ ] One-page HTML: tokens, a phone card, admin login and a table row, light and dark
- [ ] Client approval recorded; changes applied to DESIGN.md, admin globals.css and mobile theme.dart together
- [ ] Scope frozen in docs/adr/0003-scope-freeze.md
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T08-style-sheet.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

In Claude Code you can run gstack /design-consultation or /plan-design-review against DESIGN.md.
