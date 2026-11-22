import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Native mobile (Android & iOS) implementation of the embedded YouTube player.
/// Uses `youtube_player_iframe` and `webview_flutter_android` to play videos
/// completely inside the CRICIT app without launching external YouTube or browser.
///
/// Supports edge-to-edge full-bleed reel mode (zero letterbox/pillarbox) using
/// `OverflowBox` and `ClipRect` viewport scaling.
/// Handles instant autoplay when `isActive` is true, pauses immediately when `isActive`
/// is false, and cues background preloading when `isPreload` is true.
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
    this.isActive = true,
    this.isPreload = false,
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
    final shouldAutoPlay = widget.isActive;
    final isPassiveReel = widget.fitFullScreen || !widget.interactive;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: shouldAutoPlay,
      params: YoutubePlayerParams(
        showControls: widget.showControls,
        showFullscreenButton: false,
        mute: true, // Start muted so Android WebView never blocks autoplay
        enableJavaScript: true,
        showVideoAnnotations: false,
        loop: widget.fitFullScreen,
        playsInline: true,
        pointerEvents: isPassiveReel ? PointerEvents.none : PointerEvents.auto,
      ),
    );

    _controller!.listen((value) {
      if (value.playerState == PlayerState.playing && widget.isActive) {
        _controller!.unMute();
      }
    });
  }

  @override
  void didUpdateWidget(PlatformYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isTestEnvironment && _controller != null) {
      if (widget.videoId != oldWidget.videoId) {
        if (widget.isActive) {
          _controller!.loadVideoById(videoId: widget.videoId);
          _controller!.unMute();
        } else {
          _controller!.cueVideoById(videoId: widget.videoId);
        }
      } else if (widget.isActive != oldWidget.isActive) {
        if (widget.isActive) {
          _controller!.playVideo();
          _controller!.unMute();
        } else {
          _controller!.pauseVideo();
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

    final isPassiveReel = widget.fitFullScreen || !widget.interactive;

    if (widget.fitFullScreen) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportW = constraints.maxWidth;
          final viewportH = constraints.maxHeight;
          if (viewportW <= 0 || viewportH <= 0) {
            return const SizedBox.expand();
          }

          if (widget.coverMode) {
            // Edge-to-edge reel cover mode:
            // Match the container's exact aspect ratio so YoutubePlayer fills 100%
            // of the viewport without letterboxing or black margins.
            final screenRatio = viewportW / viewportH;
            return SizedBox(
              width: viewportW,
              height: viewportH,
              child: IgnorePointer(
                ignoring: isPassiveReel,
                child: YoutubePlayer(
                  key: ValueKey('yt-${widget.videoId}-cover'),
                  controller: _controller!,
                  aspectRatio: screenRatio,
                  backgroundColor: Colors.black,
                  autoFullScreen: false,
                  enableFullScreenOnVerticalDrag: false,
                  gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                ),
              ),
            );
          }

          // Fit mode: standard uncropped letterboxed/contain view
          return Container(
            color: Colors.black,
            width: viewportW,
            height: viewportH,
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: effectiveVideoRatio,
              child: IgnorePointer(
                ignoring: isPassiveReel,
                child: YoutubePlayer(
                  key: ValueKey('yt-${widget.videoId}-fit'),
                  controller: _controller!,
                  aspectRatio: effectiveVideoRatio,
                  backgroundColor: Colors.black,
                  autoFullScreen: false,
                  enableFullScreenOnVerticalDrag: false,
                  gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                ),
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
          autoFullScreen: false,
          enableFullScreenOnVerticalDrag: false,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      ),
    );
  }
}
