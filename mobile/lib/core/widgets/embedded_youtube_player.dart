import 'package:material_ui/material_ui.dart';

import 'embedded_youtube_player_stub.dart'
    if (dart.library.html) 'embedded_youtube_player_web.dart'
    if (dart.library.io) 'embedded_youtube_player_mobile.dart';

/// Embedded YouTube player widget that runs completely inside the CRICIT app.
/// On Web, uses a hardware-accelerated HTML iframe via HtmlElementView.
/// On Mobile/Test, uses the platform stub or native WebView.
/// Supports both fixed aspect ratio and full-screen height (fitFullScreen: true),
/// edge-to-edge reel cover mode (coverMode: true), autoplay lifecycle management
/// (isActive: true/false), and background preloading (isPreload: true).
class EmbeddedYouTubePlayer extends StatelessWidget {
  const EmbeddedYouTubePlayer({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.showControls = true,
    this.fitFullScreen = false,
    this.coverMode = true,
    this.interactive = true,
    this.isActive = true,
    this.isPreload = false,
    this.onEnded,
  });

  final String videoId;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool fitFullScreen;
  final bool coverMode;
  final bool interactive;
  final bool isActive;
  final bool isPreload;

  /// Called once when the video plays to its end (native mobile only).
  final VoidCallback? onEnded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: fitFullScreen ? double.infinity : null,
      color: Colors.black,
      child: PlatformYouTubePlayer(
        videoId: videoId,
        aspectRatio: aspectRatio,
        autoPlay: autoPlay,
        showControls: showControls,
        fitFullScreen: fitFullScreen,
        coverMode: coverMode,
        interactive: interactive,
        isActive: isActive,
        isPreload: isPreload,
        onEnded: onEnded,
      ),
    );
  }
}
