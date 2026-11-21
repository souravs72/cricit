# Technical Design: Zero-Latency Video Subsystem

## 1. Gesture Stack & Layering Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Interactive Controls Layer (Floating Buttons, Action Column)    │  <- HitTestBehavior.opaque
├─────────────────────────────────────────────────────────────────┤
│ Decorative Scrims (Top & Bottom Gradients for Text Legibility) │  <- IgnorePointer(ignoring: true)
├─────────────────────────────────────────────────────────────────┤
│ Tap-to-Play Gesture Arena & Video Player View                   │  <- HitTestBehavior.opaque
│ (PlatformYouTubePlayer Web Iframe / Poster Thumbnail)           │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Rules:
- All decorative elements that do not require user clicks MUST be wrapped in `IgnorePointer(ignoring: true)` to ensure zero gesture absorption.
- Interactive action buttons (Like, Save, Share, Watch Externally) have explicit hit test margins (min 48×48dp) and do not overlap the central video play zone.

## 2. Low-Latency Lifecycle & Optimization Pipeline

1. **Pre-warm**: `web/index.html` initiates DNS pre-resolution and TLS session initialization with `youtube-nocookie.com` and `i.ytimg.com`.
2. **Instant Thumbnail Render**: The video thumbnail is fetched from `cached_network_image` using disk and memory caches. First frame displays in < 16ms.
3. **Optimistic Play Activation**:
   - On tapping the play trigger (either the central card button or the thumbnail):
     - Trigger immediate haptic feedback (`HapticFeedback.lightImpact()`).
     - Set `_isPlaying = true`.
     - Instantiate `PlatformYouTubePlayer` with `autoPlay: true` and `interactive: true`.
4. **Iframe Construction**:
   - `iframe.style.pointerEvents = 'auto'` allows immediate touch control.
   - `iframe.src = 'https://www.youtube-nocookie.com/embed/{id}?autoplay=1&mute=0&playsinline=1&controls=1&rel=0&modestbranding=1&enablejsapi=1'`.
   - Feature policy `allow="autoplay; fullscreen; encrypted-media; picture-in-picture"` explicitly enabled.

## 3. Fallback & Cross-Platform Support
- On native mobile platforms or if the embed is blocked by network content filters, an unambiguous "Open in YouTube" button opens the official app or browser via `url_launcher`.
- Unit tests run against `embedded_youtube_player_stub.dart` with zero crashes or platform exceptions.
