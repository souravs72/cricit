import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the embedded YouTube player using an HTML iframe element.
/// Sets `pointer-events: none` on the iframe so that Flutter can capture all
/// swipe, drag, and flick gestures seamlessly.
/// Supports edge-to-edge reel cover mode using `OverflowBox` and `ClipRect`.
/// Supports instant autoplay lifecycle when `isActive` is true, pausing when `isActive`
/// is false, and background pre-buffering when `isPreload` is true.
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
  late String _viewType;
  static final Set<String> _registeredTypes = {};

  @override
  void initState() {
    super.initState();
    _computeViewType();
    _registerView();
  }

  void _computeViewType() {
    _viewType =
        'cricit-yt-${widget.videoId}-${widget.interactive ? "i" : "p"}-${widget.isActive ? "act" : "inact"}-${widget.showControls ? "ctrl" : "noctrl"}';
  }

  @override
  void didUpdateWidget(PlatformYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoId != oldWidget.videoId || widget.isActive != oldWidget.isActive) {
      setState(() {
        _computeViewType();
        _registerView();
      });
      // Postmessage to iframe if already loaded for smooth playback toggle
      final iframe = web.document.querySelector('iframe[src*="${widget.videoId}"]') as web.HTMLIFrameElement?;
      if (iframe != null && iframe.contentWindow != null) {
        final func = widget.isActive ? 'playVideo' : 'pauseVideo';
        final cmd = '{"event":"command","func":"$func","args":""}';
        iframe.contentWindow!.postMessage(cmd.toJS, '*'.toJS);
      }
    }
  }

  void _registerView() {
    if (_registeredTypes.contains(_viewType)) return;
    _registeredTypes.add(_viewType);

    final vId = widget.videoId;
    final auto = (widget.isActive && widget.autoPlay) ? '1' : '0';
    final mute = (!widget.isActive || widget.isPreload) ? '1' : '0';
    final controls = widget.showControls ? '1' : '0';
    final loop = widget.fitFullScreen ? '1' : '0';
    final interactive = widget.fitFullScreen ? false : widget.interactive;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src =
            'https://www.youtube-nocookie.com/embed/$vId?autoplay=$auto&mute=$mute&playsinline=1&controls=$controls&loop=$loop&playlist=$vId&rel=0&modestbranding=1&enablejsapi=1&origin=${web.window.location.origin}';
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
                  child: HtmlElementView(key: ValueKey(_viewType), viewType: _viewType),
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
              child: HtmlElementView(key: ValueKey(_viewType), viewType: _viewType),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: effectiveRatio,
        child: HtmlElementView(key: ValueKey(_viewType), viewType: _viewType),
      ),
    );
  }
}
