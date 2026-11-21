# Technical Design: Vertical Slide Animation & Native In-App YouTube Player

## 1. Vertical Slide Component Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      _TabFeed State                          │
│                                                              │
│  Listener (onPointerSignal: handles mouse wheel on Web)      │
│  └─ Stack                                                    │
│      ├─ PageView.builder (scrollDirection: Axis.vertical)   │
│      │   │                                                   │
│      │   └─ AnimatedBuilder (animation: _pageController)     │
│      │       │                                               │
│      │       ├─ Card N (outgoing):                           │
│      │       │   - Translate: y moves upward                 │
│      │       │   - Scale: 1.0 -> 0.95                        │
│      │       │   - Opacity: 1.0 -> 0.8                       │
│      │       │                                               │
│      │       └─ Card N+1 (incoming):                         │
│      │           - Translate: slides in from bottom          │
│      │           - BoxShadow: physical card elevation        │
│      │           - Scale: 1.0                                │
│      │                                                       │
│      └─ _DeckTopBar (Segmented deck indicators & Prev/Next)  │
└──────────────────────────────────────────────────────────────┘
```

### Wheel & Gesture Coordination
1. **Wheel Debounce**: On web/desktop platforms, mouse wheel emits rapid continuous delta events. A 240ms debounce latch triggers a single `_page.nextPage` or `_page.previousPage` per wheel gesture.
2. **Gesture Conflicts Removed**: Outer `GestureDetector(onVerticalDragEnd)` is eliminated to avoid stealing touch velocity from `PageView`'s native spring simulation.
3. **Discrete Card Snapping**: `PageScrollPhysics()` ensures cards always lock directly to 100% viewport alignment with no mid-way settling.

---

## 2. Cross-Platform Embedded Video Architecture

```
                   EmbeddedYouTubePlayer
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   [dart.library.js_interop]          [dart.library.io]
  embedded_youtube_player_web    embedded_youtube_player_mobile
            │                                 │
            ▼                                 ▼
   HTML5 IFrame Element              youtube_player_iframe
 (hardware-accelerated Web)        (native Android/iOS WebView)
                                              │
                                              ▼
                                    (Test Environment Guard:
                                  Zero-crash mock for flutter test)
```

### Mobile Native Player Implementation (`embedded_youtube_player_mobile.dart`)
- **Controller Lifecycle**:
  ```dart
  _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    params: const YoutubePlayerParams(
      showControls: true,
      showFullscreenButton: true,
      mute: false,
      enableJavaScript: true,
      showVideoAnnotations: false,
    ),
    autoPlay: widget.autoPlay,
  );
  ```
- **Reactivity**:
  `didUpdateWidget` compares `oldWidget.videoId != widget.videoId`. If changed, it invokes `_controller.loadVideoById(videoId: widget.videoId)`.
- **Resource Management**:
  `dispose` calls `_controller.close()` to cleanly terminate the background WebView thread and release Android surface buffers.
- **Aspect Ratio & Sizing**:
  - In `NewsCardView`: Aspect ratio 16:9 inside the 42% media canvas.
  - In `VideoShortView`: Full-screen 9:16 vertical video fitting 100% height and width.

---

## 3. UI/UX Refinements (UI-UX-Pro-Max & WCAG 2.1 AA)
- **Minimum Hit Targets**: Minimum 48×48dp on all interactive elements:
  - "Close Video" / "✕" floating button: 48×48dp touch region with high contrast border.
  - Bottom action bar buttons (Like, Save, Share, Language Toggle): 48×48dp hit bounds.
- **Card Contrast**: WCAG 2.1 AA compliant text contrast across both light (9:1) and dark mode (12:1).
- **Reduced Motion Support**: `MediaQuery.disableAnimationsOf(context)` switches transitions to instant jump cuts if user prefers reduced motion.
