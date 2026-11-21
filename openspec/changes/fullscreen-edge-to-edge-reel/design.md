# Design: Fullscreen Edge-to-Edge Reel Video Experience

## Architecture & Layout Mathematics

### 1. Viewport Scaling Math
Given viewport dimensions $W \times H$ (e.g. $390 \times 844$) and video aspect ratio $R_{\text{video}}$ (typically $16/9 \approx 1.778$ or $9/16 = 0.5625$):
- In **Reel Cover Mode** (`coverMode = true`):
  - Target height is locked to $H$ (100% of viewport height).
  - Target width is calculated as $W_{\text{target}} = H \times R_{\text{video}}$.
  - The video widget is centered in an `OverflowBox` with `minWidth: W_target, maxWidth: W_target, minHeight: H, maxHeight: H`.
  - An outer `ClipRect` clips the horizontal overflow, keeping the center of the video in full focus across the entire height of the screen.
  - This eliminates all top, bottom, and side black bars.
- In **Fit Mode** (`coverMode = false`):
  - Standard letterboxed container centered within $W \times H$.

### 2. Player Controller & Parameters
- Set `showControls: false` in Reel Mode to prevent cluttered desktop-style scrubbers.
- Set `loop: true` for continuous loop playback typical of reels.
- Web implementation uses `iframe` styled with `width: 100%`, `height: 100%`, `object-fit: cover`.

### 3. User Interaction & Touch Targets
- Accessible 44×44px hit targets for Like, Save, Share, and View Mode Toggle buttons.
- Double-tap gesture anywhere on the video triggers `coverMode` toggle with medium haptic feedback.
