import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the embedded YouTube player using an HTML iframe element.
/// Sets `pointer-events: none` on the iframe so that Flutter can capture all
/// swipe, drag, and flick gestures seamlessly.
/// Supports edge-to-edge reel cover mode using `OverflowBox` and `ClipRect`.
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
  late final String _viewType;
  static final Set<String> _registeredTypes = {};

  @override
  void initState() {
    super.initState();
    _viewType =
        'cricit-yt-${widget.videoId}-${widget.interactive ? "i" : "p"}-${widget.autoPlay ? "play" : "pause"}-${widget.showControls ? "ctrl" : "noctrl"}';
    _registerView();
  }

  void _registerView() {
    if (_registeredTypes.contains(_viewType)) return;
    _registeredTypes.add(_viewType);

    final vId = widget.videoId;
    final auto = widget.autoPlay ? '1' : '0';
    final controls = widget.showControls ? '1' : '0';
    final loop = widget.fitFullScreen ? '1' : '0';
    final interactive = widget.interactive;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src =
            'https://www.youtube-nocookie.com/embed/$vId?autoplay=$auto&playsinline=1&controls=$controls&loop=$loop&playlist=$vId&rel=0&modestbranding=1&enablejsapi=1&origin=${web.window.location.origin}';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.border = '0';
        iframe.style.objectFit = 'cover';
        iframe.style.pointerEvents = interactive ? 'auto' : 'none';
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';
        iframe.allowFullscreen = true;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRatio = widget.aspectRatio ?? (16 / 9);

    if (widget.fitFullScreen) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportW = constraints.maxWidth;
          final viewportH = constraints.maxHeight;

          if (widget.coverMode && viewportW > 0 && viewportH > 0) {
            final viewportRatio = viewportW / viewportH;
            final double targetWidth;
            final double targetHeight;

            if (viewportRatio < effectiveRatio) {
              targetHeight = viewportH;
              targetWidth = viewportH * effectiveRatio;
            } else {
              targetWidth = viewportW;
              targetHeight = viewportW / effectiveRatio;
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
                  child: HtmlElementView(viewType: _viewType),
                ),
              ),
            );
          }

          return Container(
            color: Colors.black,
            width: viewportW,
            height: viewportH,
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: effectiveRatio,
              child: HtmlElementView(viewType: _viewType),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: effectiveRatio,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
