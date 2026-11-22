# Specification: Robust Mobile Video Reels & Gesture Isolation

## 1. Problem Statement
On Android mobile devices, embedding YouTube Shorts within native WebViews caused two major UX failures:
1. **Gesture Interception**: The native Android PlatformView (`WebViewWidget`) captured vertical drag touch events, preventing Flutter's parent `PageView.builder` from receiving swipes. As a result, the user could not scroll to the next or previous video.
2. **Fullscreen Overlay Popout**: `youtube_player_iframe`'s default `enableFullScreenOnVerticalDrag` and `autoFullScreen` parameters caused the player to trigger `controller.enterFullScreen()`, detaching the video from the feed card and rendering a letterboxed black overlay across Flutter's root `OverlayPortal`. This covered up Cricit's UI metadata and action buttons.
3. **Card Container Clipping**: Wrapping the video card in an elevated rounded card with drop shadows (`margin: 4px`, `ClipRRect(16)`) made full-screen video reels look like floating external boxes ("popping out of the app").

## 2. Architectural Constraints & System Capabilities
1. **Touch Isolation (`IgnorePointer` & `PointerEvents.none`)**:
   - `PlatformYouTubePlayer` must set `PointerEvents.none` on `YoutubePlayerParams` for reel video instances.
   - The `YoutubePlayer` widget must be wrapped with `IgnorePointer(ignoring: true)` in reel mode so Flutter's hit-testing pipeline routes 100% of vertical scroll gestures directly to `PageView.builder`.
   - `gestureRecognizers` must be explicitly set to an empty set `const <Factory<OneSequenceGestureRecognizer>>{}`.
2. **Popout Prevention**:
   - `autoFullScreen: false` must be explicitly passed.
   - `enableFullScreenOnVerticalDrag: false` must be explicitly passed.
   - The player must strictly remain an inline child of `VideoShortView`.
3. **Seamless In-App Visual Integration**:
   - When on the `Video` tab (`widget.tab == 'video'`), the card must have `margin: EdgeInsets.zero`, no external drop shadow, and no outer `ClipRRect`. The video fills the viewport between the top tab bar and the bottom navigation bar seamlessly.
   - Cricit's rich overlays (Channel badge, headline, publish time, like button, bookmark button, share button, and play/pause tap overlay) remain rendered over the video with WCAG 2.1 AA compliant contrast.
   - For story tabs (`My feed`, `Domestic`, `International`), the tactile 16px rounded card deck with dynamic elevation shadows is preserved.
