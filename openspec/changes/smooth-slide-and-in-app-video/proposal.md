# Proposal: Inshorts-Style Vertical Card Slides & Native In-App Embedded Video

## 1. Problem Statement
The CRICIT mobile app currently exhibits two major UX discrepancies reported during UAT:
1. **Continuous Scroll instead of Animated Slides**:
   - The newsfeed behaves like a standard continuous scrollview rather than animated, discrete slides. On Web/desktop, mouse wheel and trackpad scroll through fractional pages without snappy page-by-page snapping. On touch devices, cards move without slide depth or animated card transition physics (the "cards moving up and down" feel of InShorts, TikTok, and Instagram Reels).
   - Outer `GestureDetector` in `_TabFeed` competed with inner `PageView`, causing sluggish gesture tracking and delayed fling animations.
2. **Videos Opening in External YouTube App Instead of In-App**:
   - When tapping video cards in the Android APK, the app opened external YouTube / Chrome browser via `url_launcher`.
   - Root Cause: `embedded_youtube_player.dart` conditionally imported `embedded_youtube_player_stub.dart` on non-web platforms. The stub had a placeholder that invoked `launchUrl(..., mode: LaunchMode.externalApplication)` instead of rendering an in-app player via `youtube_player_iframe` / `webview_flutter_android`.

## 2. Proposed Architecture & Solutions

### A. Fluid Vertical Card Slide Subsystem
- **Page-by-Page Discrete Snapping**: Enforce `PageScrollPhysics()` with strict snapping; prevent fractional scroll resting states.
- **InShorts Deck Slide Transformation**: Implement a custom page transformer using `AnimatedBuilder(animation: _page)`:
  - As card $N$ transitions to $N+1$, the outgoing card slides smoothly upward with subtle depth scaling (`0.95x`) and dimming (`0.8` opacity), while the incoming card slides up from below with physical elevation and drop shadow.
- **Wheel & Trackpad Navigation (Web/Desktop)**: Intercept mouse wheel events with `Listener(onPointerSignal: ...)` to convert wheel scrolls into debounced discrete page transitions (`nextPage()` / `previousPage()`), ensuring the web experience feels like snappy slides rather than an unconstrained web page.
- **Haptic Feedback**: Selection click haptics on slide change and medium impact on pull-to-refresh at the top of the deck.

### B. True In-App Embedded Video Playback (Native Android + Web)
- **Native Android / iOS Implementation (`embedded_youtube_player_mobile.dart`)**:
  - Leverage `youtube_player_iframe: ^6.0.2` and `webview_flutter_android: ^4.14.1`.
  - Instantiate `YoutubePlayerController.fromVideoId` with `autoPlay`, `enableJavaScript`, and `showControls`.
  - Render `YoutubePlayer` inline inside `NewsCardView`'s media canvas (aspect ratio 16:9) and in full-bleed inside `VideoShortView` (aspect ratio 9:16 / full screen).
  - Test safety: Detect `FLUTTER_TEST` or non-mobile platforms in `embedded_youtube_player_mobile.dart` and provide a zero-crash mock presentation for unit/widget tests.
- **Web Implementation (`embedded_youtube_player_web.dart`)**:
  - Maintain the high-performance HTML5 iframe with `origin`, `enablejsapi`, `playsinline=1`, and `pointerEvents: auto`.
- **Conditional Dispatch (`embedded_youtube_player.dart`)**:
  - Wire conditional compilation: `web` -> `embedded_youtube_player_web.dart`, `io` -> `embedded_youtube_player_mobile.dart`, fallback -> `embedded_youtube_player_stub.dart`.

## 3. Success Metrics
- 0 external browser redirects when tapping "Play in App" or opening the Video Shorts tab.
- 100% discrete vertical card slide transitions (snapping immediately to the next or previous card).
- Clean `flutter test` execution (15/15 passed).
- Zero TypeScript / Flutter compilation errors.
