import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the embedded YouTube player using an HTML iframe element.
/// Sets `pointer-events: none` on the iframe so that Flutter can capture all
/// swipe, drag, and flick gestures seamlessly.
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
  late final String _viewType;
  static final Set<String> _registeredTypes = {};

  @override
  void initState() {
    super.initState();
    _viewType =
        'cricit-yt-${widget.videoId}-${widget.interactive ? "i" : "p"}-${widget.autoPlay ? "play" : "pause"}';
    _registerView();
  }

  void _registerView() {
    if (_registeredTypes.contains(_viewType)) return;
    _registeredTypes.add(_viewType);

    final vId = widget.videoId;
    final auto = widget.autoPlay ? '1' : '0';
    final interactive = widget.interactive;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src =
            'https://www.youtube-nocookie.com/embed/$vId?autoplay=$auto&playsinline=1&controls=1&rel=0&modestbranding=1&enablejsapi=1&origin=${web.window.location.origin}';
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
    if (widget.fitFullScreen) {
      return SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? (16 / 9),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
