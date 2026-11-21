import 'package:flutter/material.dart';

import 'embedded_youtube_player_stub.dart'
    if (dart.library.js_interop) 'embedded_youtube_player_web.dart';

/// Embedded YouTube player widget that runs completely inside the CRICIT app.
/// On Web, uses a hardware-accelerated HTML iframe via HtmlElementView.
/// On Mobile/Test, uses the platform stub.
/// Supports both fixed aspect ratio and full-screen height (fitFullScreen: true).
class EmbeddedYouTubePlayer extends StatelessWidget {
  const EmbeddedYouTubePlayer({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.showControls = true,
    this.fitFullScreen = false,
    this.interactive = true,
  });

  final String videoId;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool fitFullScreen;
  final bool interactive;

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
        fitFullScreen: fitFullScreen,
        interactive: interactive,
      ),
    );
  }
}
