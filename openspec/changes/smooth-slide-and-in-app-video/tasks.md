# Tasks: Inshorts-Style Vertical Card Slides & In-App Embedded Video

- [x] 1. **Native Mobile Embedded YouTube Player**
  - [x] Implement `mobile/lib/core/widgets/embedded_youtube_player_mobile.dart` utilizing `youtube_player_iframe` and `YoutubePlayerController`.
  - [x] Add safety check for `FLUTTER_TEST` or non-Android/iOS host environments to prevent missing plugin crashes in widget tests.
  - [x] Update `mobile/lib/core/widgets/embedded_youtube_player.dart` with conditional import (`if (dart.library.io) 'embedded_youtube_player_mobile.dart'`).

- [x] 2. **Inshorts-Style Vertical Card Slide Animation**
  - [x] Refactor `_TabFeedState` in `mobile/lib/features/feed/presentation/feed_screen.dart` to remove conflicting outer `GestureDetector`.
  - [x] Implement `AnimatedBuilder` page transformer that animates outgoing cards upward with scale/dimming while incoming cards slide in cleanly from below.
  - [x] Add mouse wheel / trackpad pointer signal listener with debounced discrete page transitions for Web/desktop.

- [x] 3. **UI/UX Polish & Player Controls**
  - [x] Add smooth "Close Video" overlay button on `NewsCardView` to return to thumbnail.
  - [x] Ensure `VideoShortView` plays embedded YouTube short natively without external redirect.
  - [x] Verify 48×48dp hit targets and haptic feedback on all action controls.

- [x] 4. **Automated Verification & Tests**
  - [x] Run `flutter test` across all mobile test suites (15/15 passed).
  - [x] Run `flutter analyze` to ensure zero warnings or errors (0 issues found).

- [x] 5. **Release Build & Deployment**
  - [x] Build release web bundle and sync to production server (`/opt/cricit/mobile/build/web`).
  - [x] Build release Android APK (`assembleDevRelease`) and sync to `/home/ascra/Downloads/cricit/cricit-dev-release.apk` and remote server (`/opt/cricit/mobile/build/web/cricit.apk`).
