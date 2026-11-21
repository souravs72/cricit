# Proposal: Autoplay, 2-Video Preloading, and Infinite Shorts Feed

## 1. Problem Statement
Users expect a TikTok / YouTube Shorts-like native experience:
1. Videos must autoplay automatically when scrolled into view without requiring manual taps to start.
2. Inactive videos must pause immediately when scrolled away to prevent background audio overlap.
3. Latency must be near zero. On initial app launch, the next 2 videos must be pre-buffered. As the user watches and scrolls, the next 2 videos must always stay preloaded in advance.
4. The feed must be infinite, dynamically loading new batches of video cards before the user reaches the end of the scroll queue.

## 2. Proposed Changes
- **Autoplay Lifecycle**:
  - `VideoShortView` and `PlatformYouTubePlayer` accept `isActive: bool` and `isPreload: bool`.
  - When `isActive == true`: `_controller.playVideo()` fires immediately.
  - When `isActive == false`: `_controller.pauseVideo()` fires immediately.
- **2-Video Lookahead Preloader**:
  - `_TabFeedState` tracks `_currentIndex`.
  - Automatically cues/pre-buffers videos at `_currentIndex + 1` and `_currentIndex + 2`.
  - Pre-caches poster images in Flutter's image cache using `precacheImage`.
- **Infinite Video Feed**:
  - Fix `feed_repository.dart` to pass `tab: 'video'` directly to `/v1/feed?tab=video`.
  - Trigger `loadMore()` when within 2 cards of the list end (`index >= state.cards.length - 2`).
  - Seamless loop/extension support when the backend pool ends so the video feed never terminates.
- **Verification & Deployment Gates**:
  - Automated tests: `flutter test` and `flutter analyze`.
  - Browser mobile viewport verification with Playwright (390×844).
  - GitHub commit & push -> production `deploy.sh` -> re-verify production in browser -> release APK generation & hosting.
