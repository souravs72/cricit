# Change Proposal: Zero-Latency Instant Video Playback in CRICIT Mobile

## 1. Problem Statement
Users report that tapping on cricket videos within the mobile application does not start playback. Specifically:
1. **Pointer Event Interception**: In `VideoShortView` and `NewsCardView`, decorative gradient scrims and top vignettes (`Positioned.fill(Container(...))`) sit directly on top of the video canvas without `IgnorePointer`. In Flutter's render tree, decorated containers consume touch events, starving the video widget and play controls of tap gestures.
2. **Web Iframe Event Suppression**: In `embedded_youtube_player_web.dart`, `iframe.style.pointerEvents = 'none'` is hardcoded whenever `!interactive` (with `interactive` defaulting to `false`). This prevents user clicks from reaching the underlying video element.
3. **Autoplay Policy Blockers**: Browsers restrict unmuted autoplay without prior user interaction. When `autoplay=1` is passed without `mute=1`, the browser cancels playback.
4. **Cold Start Latency**: Without DNS prefetching and early asset preconnection, establishing TLS connections to YouTube CDNs causes perceptible delay on mobile networks.

## 2. Proposed Architecture & Solution
1. **Non-Blocking Gesture Hierarchy**:
   - Wrap all aesthetic gradient overlays and text legibility scrims in `IgnorePointer(ignoring: true)` so taps pass freely to the underlying video canvas and controls.
   - Separate the interactive HUD (floating like, bookmark, share buttons) into dedicated, hit-tested touch targets meeting the 48×48dp standard.
2. **Instant Responsive Play State Machine**:
   - Provide instant visual haptic feedback (`HapticFeedback.lightImpact()`) on tapping the play button or video canvas.
   - Show the cached poster image (`CachedNetworkImage` with `hqdefault.jpg`) as an immediate high-resolution placeholder while the player buffers, avoiding blank/black screen flash.
3. **Optimized Iframe Embed for Flutter Web**:
   - Enable pointer events (`pointerEvents = 'auto'`) when the video enters the playing state so user controls (play/pause, seek, audio) respond instantly.
   - Configure embed parameters: `autoplay=1&mute=0&playsinline=1&controls=1&rel=0&modestbranding=1&enablejsapi=1`.
   - Add a direct "Watch on YouTube / External App" fallback action button to ensure 100% reliability regardless of browser sandboxing.
4. **Latency Optimization (Preconnect & Preload)**:
   - Add `<link rel="preconnect" href="https://www.youtube-nocookie.com">` and `<link rel="preconnect" href="https://i.ytimg.com">` in `mobile/web/index.html`.
   - Pre-warm the player with low-overhead embed parameters.

## 3. Scope & Boundaries
- Affects: `mobile/lib/features/feed/presentation/video_short_view.dart`, `mobile/lib/features/feed/presentation/news_card_view.dart`, `mobile/lib/core/widgets/embedded_youtube_player.dart`, `embedded_youtube_player_web.dart`, `embedded_youtube_player_stub.dart`, `mobile/web/index.html`.
- Maintains full test coverage and compatibility with desktop/unit tests.
