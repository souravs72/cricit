# T08 — Client approves the visual style sheet

**Week:** W2 · **Estimate:** ~3 h · **Depends on:** -

## Goal

Lock the look before UI work starts.

## Files

- `DESIGN.md`
- `docs/style-sheet.html (new, one page)`

## Acceptance

- [ ] One-page HTML showing tokens, a phone card, the admin login and a table row, in light and dark
- [ ] Client approval recorded; any change is applied to DESIGN.md, globals.css and theme.dart together
- [ ] Scope frozen: list of v1 features signed in docs/adr/0002-scope-freeze.md
- [ ] `make check` (or the app's target) passes and the result is pasted in the PR

## How to start in Cursor

> Implement `docs/tickets/T08-style-sheet.md`. Read AGENTS.md first. Write the tests for the
> Acceptance list first, then the code. Run the checks and report the real output before finishing.

## Notes

In Claude Code you can run gstack /design-consultation or /plan-design-review against DESIGN.md.
