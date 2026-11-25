import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:material_ui/material_ui.dart';
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
  final VoidCallback? onEnded;

  @override
  State<PlatformYouTubePlayer> createState() => _PlatformYouTubePlayerState();
}

class _PlatformYouTubePlayerState extends State<PlatformYouTubePlayer> {
  late String _viewType;
  web.HTMLIFrameElement? _iframe;
  static final Set<String> _registeredTypes = {};
  static int _instances = 0;
  final int _instanceId = _instances++;

  @override
  void initState() {
    super.initState();
    _computeViewType();
    _registerView();
  }

  // The view type deliberately does NOT include isActive: a preloaded iframe
  // must survive activation, otherwise it is torn down and reloaded from
  // scratch exactly when the person swipes to it.
  void _computeViewType() {
    _viewType =
        'cricit-yt-${widget.videoId}-${widget.interactive ? "i" : "p"}-${widget.showControls ? "ctrl" : "noctrl"}-$_instanceId';
  }

  void _command(String func) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    final cmd = '{"event":"command","func":"$func","args":""}';
    win.postMessage(cmd.toJS, '*'.toJS);
  }

  @override
  void didUpdateWidget(PlatformYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoId != oldWidget.videoId) {
      setState(() {
        _iframe = null;
        _computeViewType();
        _registerView();
      });
    } else if (widget.isActive != oldWidget.isActive) {
      _command(widget.isActive ? 'playVideo' : 'pauseVideo');
    }
  }

  @override
  void dispose() {
    _iframe = null;
    super.dispose();
  }

  void _registerView() {
    if (_registeredTypes.contains(_viewType)) return;
    _registeredTypes.add(_viewType);

    final vId = widget.videoId;
    final auto = widget.isActive ? '1' : '0';
    // Mute must be 1 on initial load so browser autoplay policy allows immediate zero-click playback
    const mute = '1';
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
        // If this reel was activated while its iframe was still loading,
        // start it as soon as the player can take commands.
        iframe.onload = ((web.Event _) {
          if (mounted && widget.isActive) _command('playVideo');
        }).toJS;
        _iframe = iframe;
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
                  child: HtmlElementView(
                    key: ValueKey(_viewType),
                    viewType: _viewType,
                  ),
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
              child: HtmlElementView(
                key: ValueKey(_viewType),
                viewType: _viewType,
              ),
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
