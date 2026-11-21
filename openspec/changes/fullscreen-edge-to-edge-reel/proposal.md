# Proposal: Fullscreen Edge-to-Edge Reel Video Experience

## 1. Problem Statement
The user reported that cricket videos in the mobile app play inside a tiny ~219px letterboxed container with large black borders above, below, left, and right (as seen in `media_1795258066319_7b31b6bb.jpg`). Modern short-form video expectations (Instagram Reels, TikTok, YouTube Shorts) require 100% full-bleed, edge-to-edge vertical presentation with zero letterboxing.

## 2. Solution Overview
1. **Edge-to-Edge Reel Canvas**: Implement dynamic `OverflowBox` + `ClipRect` scaling in `PlatformYouTubePlayer` (both mobile and web) so that videos scale to fill 100% of the viewport height and width seamlessly with zero black bars.
2. **Reel Fill vs. Fit Toggle**: Provide seamless switching between **Reel Fill Mode** (100% full-bleed vertical cover, default) and **Fit Mode** (full uncropped frame).
3. **Double-Tap Quick Toggle**: Allow users to double-tap the video canvas or tap a modern floating pill button (`[ ⛶ Reel Fill / ⊡ Fit Video ]`) with haptic feedback.
4. **Clean Floating HUD**: Floating badges (CRICIT VIDEO, channel verified pill, headline, summary, like/save/share actions) overlay seamlessly over the full-bleed video with a refined gradient scrim for readability.
5. **OTA Production Deployment**: Build the release APK (`cricit-dev-release.apk`), commit and push exclusively via GitHub, deploy to production at `http://137.23.51.182`, and host the updated APK for direct download.
