# Design System Master File

> **Canonical tokens live in `/DESIGN.md`.** This file is the UI/UX Pro Max companion:
> Swiss/minimal editorial, subtle motion, standard density. Do not use the generic
> sports-red palette the generator suggested — CRICIT's materials are outfield green,
> Test-ball red, sightscreen, and scoreboard amber.

**Project:** CRICIT
**Generated:** 2026-10-28
**Category:** News/Media · Android-first mobile
**Design Dials:** Variance 4/10 | Motion 3/10 (subtle) | Density 5/10

---

## Global Rules

### Color Palette (from DESIGN.md)

| Role | Hex | Usage |
|------|-----|--------|
| Outfield / primary | `#17402B` | Brand, primary actions only |
| On-outfield | `#FFFFFF` | Text on primary |
| Ball | `#C1272D` | Breaking news + destructive. At most once per screen |
| Scoreboard | `#E8A317` | Live / new only |
| Sightscreen | `#F7F9FA` | App background |
| Surface | `#FFFFFF` | Cards |
| Ink | `#1B2430` | Body text |
| Ink muted | `#5B6672` | Secondary text |
| Seam | `#D9DEE3` | Borders, not shadows |
| Success | `#2F7A52` | Confirmations |

Dark: `outfield #7BC79A`, `ball #F0646A`, `scoreboard #F2BE4E`, `sightscreen #0F1A15`, `ink #E6ECE8`, `seam #26362D`, muted `#9FB0A7`.

### Typography

- Display: **Barlow Condensed** 600 — one bold element per screen (the card headline)
- Body: **Source Sans 3** 16/24
- Hindi: **Noto Sans Devanagari** 16/26
- Sentence case everywhere. No all-caps labels

### Layout

- Mobile card: image 42% of height, headline, ~60-word summary, source row
- 4 px team-colour edge when a team tag exists
- Radius 6 / 12 / full. Spacing 4 / 8 / 16 / 24 / 32 / 48
- Surfaces separated by spacing and seam, not shadows
- Bottom nav ≤ 3 destinations (Search, Home, Profile); feed categories are tabs
- Touch: 48×48 dp Android, 8 dp gap between targets
- Safe areas respected; text scale capped at 130%

### Motion

Only in response to a person acting (card swipe, new-posts pill, sheet). Respect reduced motion. No page-load entrance animations.

### Copy

Plain verbs, sentence case. Buttons name the result. Errors say what happened and how to fix it. Empty states say what will appear and how.

### Avoid

Emoji as icons, purple/gradient AI chrome, all-caps eyebrows, identical rounded stat cards, fade-up on every section, colour as the only signal.
