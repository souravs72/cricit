# Tasks: Autoplay, Preloading & Infinite Video Feed

- [x] 1. OpenSpec proposal, design, and checklist created.
- [x] 2. Fix `feed_repository.dart` to send `tab: tab` (enabling native backend `/v1/feed?tab=video` querying).
- [x] 3. Enhance `feed_controller.dart` for infinite video reel extension and prefetching when within 2 cards.
- [x] 4. Update `embedded_youtube_player.dart` and platform implementations with `isActive` and `isPreload` lifecycle hooks.
- [x] 5. Update `video_short_view.dart` to consume `isActive` and `isPreload`, autoplaying when active and pausing when inactive.
- [x] 6. Update `feed_screen.dart` to pass active/preload flags and preload the next 2 cards' media.
- [x] 7. Update widget tests in `video_short_view_test.dart` and `feed_screen_swipe_test.dart`.
- [x] 8. Verify with `flutter test` and `flutter analyze`.
- [x] 9. Test locally on browser in mobile view (390×844) with Playwright.
- [x] 10. Commit & push changes via GitHub `main`.
- [x] 11. Deploy to production server `137.23.51.182` via `./infra/oci/deploy.sh`.
- [x] 12. Verify deployment on production browser mobile view with Playwright.
- [x] 13. Build release APK (`flutter build apk`), upload to server, and verify OTA download.
