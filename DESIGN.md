---
# gstack: design-md-format=spec
name: CRICIT
description: Cricket's own materials — outfield green, Test-ball red, sightscreen white, scoreboard amber — with condensed scoreboard type; calm, fast, editorial.
colors:
  outfield: "#17402B"
  on-outfield: "#FFFFFF"
  ball: "#C1272D"
  scoreboard: "#E8A317"
  sightscreen: "#F7F9FA"
  ink: "#1B2430"
  ink-muted: "#5B6672"
  seam: "#D9DEE3"
  surface: "#FFFFFF"
  success: "#2F7A52"
  warning: "#E8A317"
  error: "#C1272D"
  outfield-dark: "#7BC79A"
  ball-dark: "#F0646A"
  scoreboard-dark: "#F2BE4E"
  sightscreen-dark: "#0F1A15"
  ink-dark: "#E6ECE8"
  seam-dark: "#26362D"
typography:
  display:
    fontFamily: Barlow Condensed
    fontWeight: 600
    fontSize: 1.625rem
    letterSpacing: -0.01em
  body:
    fontFamily: Source Sans 3
    fontSize: 1rem
    lineHeight: 1.5
  label:
    fontFamily: Source Sans 3
    fontSize: 0.875rem
    letterSpacing: 0em
  hindi:
    fontFamily: Noto Sans Devanagari
    fontSize: 1rem
    lineHeight: 1.625
rounded:
  sm: 6px
  md: 12px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.outfield}"
    textColor: "{colors.on-outfield}"
    rounded: "{rounded.sm}"
  button-destructive:
    backgroundColor: "{colors.ball}"
    textColor: "{colors.on-outfield}"
    rounded: "{rounded.sm}"
  input:
    borderColor: "{colors.seam}"
    rounded: "{rounded.sm}"
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.seam}"
    rounded: "{rounded.md}"
  news-card-edge:
    width: 4px
    note: team colour from mobile/lib/app/theme.dart CricitColors.teams
  live-pill:
    backgroundColor: "{colors.scoreboard}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
---

# CRICIT design system

## Where the look comes from

The palette is the ground itself: the outfield, the red of a Test ball, the white sightscreen behind the
bowler's arm, and the amber of a stadium scoreboard. Headlines and figures use a condensed face because
that is how cricket has always printed its numbers — on scoreboards. It is deliberately not the
Inshorts look (white, blue accents, generic sans), which the brief asks us to stay clear of.

## Colour roles

- **Outfield** is the brand and the only primary action colour.
- **Ball** is reserved for breaking news and destructive actions. If it appears more than once on a
  screen, one of them is wrong.
- **Scoreboard** means "live" or "new" and nothing else.
- Surfaces are separated by spacing and the seam colour, not shadows.

## Type

- The condensed headline is the one bold element on any screen; everything around it stays quiet.
- Sentence case everywhere. No all-caps labels, no letter-spaced eyebrows above headings.
- Hindi text uses Noto Sans Devanagari at the same scale with extra line height.

## Layout

- Mobile card: image 42% of the screen height, then headline, ~60-word summary, source row.
  A 4 px team-colour edge on the left when the card has a team tag — CRICIT's visual signature.
- Admin: left navigation, dense tables (40 px rows), detail panels slide in from the right so the list
  stays visible. Today's numbers sit in a scoreboard strip, not a row of stat cards.
- Radius by hierarchy: 6 px controls, 12 px cards and sheets, full pills only for chips.

## Motion

Only where the person acts: the card swipe, the "New posts" pill, a sheet opening. No entrance
animations on page load. Reduced-motion settings are respected.

## Floor

WCAG AA contrast, visible keyboard focus in the admin, app text scales to 130% without clipping,
every icon-only control has a label.

## Copy

Plain verbs, sentence case. A button names its result ("Publish" → toast "Published"). Errors say what
happened and how to fix it, without apologising. Empty states say what will appear and how to make it
appear.
