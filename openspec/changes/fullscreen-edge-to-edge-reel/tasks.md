# Tasks: Fullscreen Edge-to-Edge Reel Video Experience

- [x] 1. OpenSpec proposal, design, and task checklist created.
- [x] 2. Update `mobile/lib/core/widgets/embedded_youtube_player.dart` to support `coverMode`.
- [x] 3. Update `mobile/lib/core/widgets/embedded_youtube_player_mobile.dart` with `OverflowBox` + `ClipRect` cover scaling.
- [x] 4. Update `mobile/lib/core/widgets/embedded_youtube_player_web.dart` with matching cover scaling.
- [x] 5. Update `mobile/lib/core/widgets/embedded_youtube_player_stub.dart` with matching signatures.
- [x] 6. Update `mobile/lib/features/feed/presentation/video_short_view.dart` with full-screen reel defaults, double-tap toggle, and floating mode button.
- [x] 7. Update widget tests in `mobile/test/video_short_view_test.dart` to verify full-bleed rendering and mode toggle.
- [x] 8. Verify with `flutter test` (all 16 tests pass) and `flutter analyze` (0 warnings).
- [x] 9. Build release web bundle and release Android APK (`cricit-dev-release.apk`).
- [x] 10. Commit & push changes via GitHub `main` branch.
- [x] 11. Trigger remote deployment via `infra/oci/deploy.sh` (git pull origin main on production server `137.23.51.182`).
- [x] 12. Upload and verify updated APK is downloadable at `http://137.23.51.182/app/cricit.apk`.
