# Design: Autoplay, Preloading Engine & Infinite Video Feed

## 1. Lifecycle State Machine
Each video card index $i$ in `PageView.builder` operates in one of three states relative to the active index $k$:
1. **Active** ($i == k$):
   - Player initialized, video playing, audio active, full-bleed reel mode.
2. **Preloaded** ($i \in \{k + 1, k + 2\}$):
   - Player initialized, video cued (`cueVideoById`), muted, buffered in WebView/RAM, high-res thumbnail cached in GPU texture memory.
   - Ready to transition to Active within < 16ms upon swipe completion.
3. **Inactive** ($i < k$ or $i > k + 2$):
   - Player paused or disposed to conserve memory and network bandwidth.

## 2. Dynamic Video Prefetching & Infinite Feed
- In `feed_controller.dart`:
  - Threshold changed from `cards.length - 5` to `cards.length - 2` for aggressive prefetching.
  - When backend reaches end of cursor on `tab == 'video'`, the controller smoothly clones or extends published video items with unique surrogate keys so the PageView never runs out of slides.
- In `feed_repository.dart`:
  - Request `/v1/feed?tab=video` directly rather than overriding to `feed`.

## 3. Web & Mobile Player Coordination
- `PlatformYouTubePlayer`:
  - Supports `isActive` and `isPreload`.
  - Android/iOS: `_controller.playVideo()` on active, `_controller.pauseVideo()` on inactive.
  - Web: postMessage / JavaScript bridge to trigger iframe play/pause.
