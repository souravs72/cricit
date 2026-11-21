import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Native mobile (Android & iOS) implementation of the embedded YouTube player.
/// Uses `youtube_player_iframe` and `webview_flutter_android` to play videos
/// completely inside the CRICIT app without launching external YouTube or browser.
///
/// Supports edge-to-edge full-bleed reel mode (zero letterbox/pillarbox) using
/// `OverflowBox` and `ClipRect` viewport scaling.
///
/// In headless unit/widget test environments (e.g. `flutter test` on desktop/CI),
/// it safely returns a mock presentation to avoid missing platform channel errors.
class PlatformYouTubePlayer extends StatefulWidget {
  const PlatformYouTubePlayer({
    super.key,
    required this.videoId,
    this.aspectRatio,
    this.autoPlay = false,
    this.showControls = true,
    this.fitFullScreen = false,
    this.coverMode = true,
    this.interactive = true,
  });

  final String videoId;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool fitFullScreen;
  final bool coverMode;
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
      params: YoutubePlayerParams(
        showControls: widget.showControls,
        showFullscreenButton: false,
        mute: false,
        enableJavaScript: true,
        showVideoAnnotations: false,
        loop: widget.fitFullScreen,
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
    final effectiveVideoRatio = widget.aspectRatio ?? (16 / 9);

    // Zero-crash mock representation for headless tests or desktop environments
    if (_isTestEnvironment || _controller == null) {
      return Container(
        key: ValueKey('test-yt-${widget.videoId}'),
        color: Colors.black,
        width: double.infinity,
        height: widget.fitFullScreen ? double.infinity : null,
        child: AspectRatio(
          aspectRatio: effectiveVideoRatio,
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

    if (widget.fitFullScreen) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportW = constraints.maxWidth;
          final viewportH = constraints.maxHeight;

          if (widget.coverMode && viewportW > 0 && viewportH > 0) {
            // Edge-to-edge reel cover mode:
            // Calculate target dimensions so the video covers 100% of the viewport.
            // When viewport is portrait (e.g. 9:19) and video is 16:9 landscape:
            // targetHeight = viewportH, targetWidth = viewportH * effectiveVideoRatio.
            // When viewport is wider than the video ratio:
            // targetWidth = viewportW, targetHeight = viewportW / effectiveVideoRatio.
            final viewportRatio = viewportW / viewportH;
            final double targetWidth;
            final double targetHeight;

            if (viewportRatio < effectiveVideoRatio) {
              // Viewport is taller than video (typical portrait phone): scale by height
              targetHeight = viewportH;
              targetWidth = viewportH * effectiveVideoRatio;
            } else {
              // Viewport is wider than video: scale by width
              targetWidth = viewportW;
              targetHeight = viewportW / effectiveVideoRatio;
            }

            return ClipRect(
              child: SizedBox(
                width: viewportW,
                height: viewportH,
                child: OverflowBox(
                  minWidth: targetWidth,
                  maxWidth: targetWidth,
                  minHeight: targetHeight,
                  maxHeight: targetHeight,
                  alignment: Alignment.center,
                  child: YoutubePlayer(
                    controller: _controller!,
                    aspectRatio: effectiveVideoRatio,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
            );
          }

          // Fit mode: standard letterboxed/contain view
          return Container(
            color: Colors.black,
            width: viewportW,
            height: viewportH,
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: effectiveVideoRatio,
              child: YoutubePlayer(
                controller: _controller!,
                aspectRatio: effectiveVideoRatio,
                backgroundColor: Colors.black,
              ),
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: effectiveVideoRatio,
        child: YoutubePlayer(
          controller: _controller!,
          aspectRatio: effectiveVideoRatio,
          backgroundColor: Colors.black,
        ),
      ),
    );
  }
}
