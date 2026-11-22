# Design: Card Deck Swipe Animation & Video Shorts Architecture

## 1. Physical Card Stack Transition
Instead of document-style smooth scrolling or destructive scale transforms:
- The `PageView` is equipped with `PageScrollPhysics(parent: ClampingScrollPhysics())` for tactile snapping.
- Each page is enclosed in a rounded card canvas (`BorderRadius.circular(16)`) with a deep drop shadow (`blurRadius: 24`, `spreadRadius: 4`).
- Transition logic:
  - When card $i$ is incoming or outgoing, it slides vertically without scale changes (`scale: 1.0`).
  - Active card retains 100% full bleed.
  - Outgoing card lifts away with elevation shadow onto the incoming card, achieving the physical deck swipe feeling.

## 2. Key Isolation & Platform View Protection
- In Flutter, Android platform views (`AndroidView`) recompute layout bounds when parent widgets scale.
- Removing `Transform.scale` eliminates the shrinking bug permanently.
- Each `VideoShortView` and `EmbeddedYouTubePlayer` receives a unique `ValueKey(card.id)`.

## 3. Seed Migration & Database Expansion
- Seed 20 diverse, verified YouTube Shorts / clips directly into `posts` table on PostgreSQL.
- Add corresponding entries to `fixture_feed.dart` for offline/fallback parity.
