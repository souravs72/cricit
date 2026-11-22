# Proposal: Physical Card Deck Swiping & Diverse Infinite Cricket Shorts

## 1. Problem Statement
The user reported two critical UX issues:
1. **Video Shrinking & Repetition**: Upon scrolling, the user saw the same video repeated and it shrunk to a small size. This occurred because:
   - `Transform.scale` was being applied during the page animation on the Android platform view WebView, which permanently deformed the render target size.
   - Video widgets lacked distinct `Key` instances, causing Flutter to recycle the previous video's state and controller.
   - The database only contained 4 video rows with duplicated video IDs (`Bo6F3zBliQY`).
2. **Card Swiped Above / Below**: Normal continuous document scrolling does not feel like high-end modern card decks (e.g. Inshorts / Reels / TikTok). The user wants a distinct physical card transition where cards swipe cleanly above and below.

## 2. Proposed Changes
1. **Card Deck Swiping Architecture**:
   - Replace scaling transformations with a true physical card deck transition (`Transform.translate` + `ClipRRect(borderRadius: 16)` + dynamic depth `BoxShadow`).
   - Cards slide cleanly above and below like stacked physical cards without shrinking the player or distorting the WebView.
2. **State & Key Isolation**:
   - Assign explicit `ValueKey('short-${card.id}-${card.videoId}')` to `VideoShortView` and `EmbeddedYouTubePlayer` so each video is completely independent.
3. **Diverse Cricket Shorts Pool**:
   - Populate database and local fallback feeds with 20 distinct, verified high-quality cricket clips (Bumrah, Kohli, Dhoni, Pant, Rohit, Surya, Hardik, Maxwell, Starc, etc.).
   - Expand continuous infinite prefetching so users never run out of distinct video shorts.
4. **Verification & Testing Protocol**:
   - Test locally and in browser mobile view (390×844) with Playwright.
   - Conventional commit, push to GitHub `main`, deploy to production server `137.23.51.182`.
   - Re-test in production mobile view with Playwright before compiling and hosting the new APK.
