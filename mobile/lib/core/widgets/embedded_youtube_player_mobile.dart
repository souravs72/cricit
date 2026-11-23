import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'video_frame_math.dart';

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
  bool _started = false;

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

    // YoutubePlayer (the package widget) normally does this; we render the
    // WebView ourselves, inline, so we must initialise the controller.
    _controller!.webViewController.setBackgroundColor(Colors.black);
    _controller!.initWithParams(params: _controller!.params);

    _controller!.listen((value) {
      final state = value.playerState;
      if (!mounted) return;
      if (state == PlayerState.playing && widget.isActive) {
        _controller!.unMute();
      }
      // Player became ready after the page was already activated -> play.
      if ((state == PlayerState.cued || state == PlayerState.unStarted) &&
          widget.isActive &&
          widget.autoPlay) {
        _controller!.playVideo();
      }
      // Went off-screen while loading/auto-playing -> stop.
      if (state == PlayerState.playing && !widget.isActive) {
        _controller!.pauseVideo();
      }
      if (!_started &&
          (state == PlayerState.playing || state == PlayerState.buffering)) {
        setState(() => _started = true);
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

    // The WebView is rendered INLINE (never in the root overlay) so it scrolls
    // with the PageView and sits under Cricit's own UI. It never receives
    // touches in reel mode, so every swipe reaches the PageView.
    Widget webView() => IgnorePointer(
          ignoring: isPassiveReel,
          child: WebViewWidget(
            key: ValueKey('wv-${widget.videoId}'),
            controller: _controller!.webViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          ),
        );

    final thumbnail = Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _started ? 0 : 1,
          child: ColoredBox(
            color: Colors.black,
            child: Image.network(
              YoutubePlayerController.getThumbnail(
                videoId: widget.videoId,
                quality: ThumbnailQuality.high,
                format: ThumbnailFormat.jpeg,
              ),
              fit: widget.coverMode ? BoxFit.cover : BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    if (widget.fitFullScreen) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final frame = computeVideoFrame(
            viewport,
            effectiveVideoRatio,
            cover: widget.coverMode,
          );
          if (frame.isEmpty) return const SizedBox.expand();
          return SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  OverflowBox(
                    alignment: Alignment.center,
                    minWidth: frame.width,
                    maxWidth: frame.width,
                    minHeight: frame.height,
                    maxHeight: frame.height,
                    child: webView(),
                  ),
                  thumbnail,
                ],
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
        child: webView(),
      ),
    );
  }
}
