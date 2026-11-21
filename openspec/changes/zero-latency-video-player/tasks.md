# Tasks: Zero-Latency Video Subsystem

- [x] 1. **Web Preconnect & Performance Initialization**
  - [x] Add preconnect and dns-prefetch links for `https://www.youtube-nocookie.com` and `https://i.ytimg.com` in `mobile/web/index.html`.

- [x] 2. **Embedded YouTube Player Core Upgrade**
  - [x] Update `embedded_youtube_player.dart` to default `interactive: true` and pass `autoPlay: true` when activated.
  - [x] Update `embedded_youtube_player_web.dart` to ensure `pointerEvents: auto` is set, proper query parameters (`autoplay=1&mute=0&playsinline=1&controls=1&rel=0&modestbranding=1&enablejsapi=1`) are attached, and iframe permissions allow instant playback.
  - [x] Update `embedded_youtube_player_stub.dart` with interactive tap action to launch video directly via `url_launcher`.

- [x] 3. **VideoShortView Non-Blocking Touch Architecture**
  - [x] Wrap gradient scrims and top/bottom decoration in `IgnorePointer(ignoring: true)` in `video_short_view.dart`.
  - [x] Ensure play/pause overlay and tap-to-play area receive touches without conflict.
  - [x] Provide explicit 48×48dp touch targets on action buttons (Like, Save, Share, Watch External).

- [x] 4. **NewsCardView Embedded Video Fix**
  - [x] Wrap vignette and decorative gradients in `IgnorePointer(ignoring: true)`.
  - [x] Enable `interactive: true` on `EmbeddedYouTubePlayer` in `news_card_view.dart`.
  - [x] Ensure tap on "Play in App" transitions immediately to active playback.

- [x] 5. **Unit & Widget Testing Verification**
  - [x] Update `video_short_view_test.dart` and `news_card_view_test.dart` to verify play tap and non-blocking gesture hierarchy.
  - [x] Fix `feed_screen_swipe_test.dart` to test vertical scroll navigation.
  - [x] Run `flutter test` across all mobile test suites (15/15 passed).

- [x] 6. **Production Android APK Delivery**
  - [x] Compile release APK with `assembleDevRelease` (configured with `API_BASE_URL=http://137.23.51.182` and `usesCleartextTraffic=true`).
  - [x] Copy APK to local path `/home/ascra/Downloads/cricit/cricit-dev-release.apk`.
  - [x] Deploy APK to remote server for direct over-the-air browser download at `http://137.23.51.182/app/cricit.apk`.
