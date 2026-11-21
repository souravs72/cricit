import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Native mobile (Android & iOS) implementation of the embedded YouTube player.
/// Uses `youtube_player_iframe` and `webview_flutter_android` to play videos
/// completely inside the CRICIT app without launching external YouTube or browser.
///
/// In headless unit/widget test environments (e.g. `flutter test` on desktop/CI),
/// it safely returns a mock presentation to avoid missing platform channel errors.
class PlatformYouTubePlayer extends StatefulWidget {
  const PlatformYouTubePlayer({
    super.key,
    required this.videoId,
    this.aspectRatio,
    this.autoPlay = false,
    this.fitFullScreen = false,
    this.interactive = true,
  });

  final String videoId;
  final double? aspectRatio;
  final bool autoPlay;
  final bool fitFullScreen;
  final bool interactive;

  @override
  State<PlatformYouTubePlayer> createState() => _PlatformYouTubePlayerState();
}

class _PlatformYouTubePlayerState extends State<PlatformYouTubePlayer> {
  YoutubePlayerController? _controller;
  bool _isTestEnvironment = false;

  @override
  void initState() {
    super.initState();
    _isTestEnvironment = Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS);

    if (!_isTestEnvironment) {
      _initController();
    }
  }

  void _initController() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableJavaScript: true,
        showVideoAnnotations: false,
        loop: false,
      ),
    );
  }

  @override
  void didUpdateWidget(PlatformYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isTestEnvironment && widget.videoId != oldWidget.videoId) {
      if (_controller != null) {
        if (widget.autoPlay) {
          _controller!.loadVideoById(videoId: widget.videoId);
        } else {
          _controller!.cueVideoById(videoId: widget.videoId);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Zero-crash mock representation for headless tests or desktop environments
    if (_isTestEnvironment || _controller == null) {
      return Container(
        key: ValueKey('test-yt-${widget.videoId}'),
        color: Colors.black,
        width: double.infinity,
        height: widget.fitFullScreen ? double.infinity : null,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio ??
              (widget.fitFullScreen ? (9 / 16) : (16 / 9)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 48,
                  color: Color(0xFFE50914),
                ),
                const SizedBox(height: 6),
                Text(
                  'Embedded Video: ${widget.videoId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final playerWidget = YoutubePlayer(
      controller: _controller!,
      aspectRatio: widget.aspectRatio ??
          (widget.fitFullScreen ? (9 / 16) : (16 / 9)),
      backgroundColor: Colors.black,
    );

    if (widget.fitFullScreen) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: playerWidget,
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? (16 / 9),
        child: playerWidget,
      ),
    );
  }
}
