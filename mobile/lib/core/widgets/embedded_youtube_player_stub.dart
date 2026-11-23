import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fallback / stub implementation for embedded YouTube player.
/// Avoids webview_flutter assertion crashes during unit tests and on non-web environments.
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
  Future<void> _launch() async {
    await HapticFeedback.lightImpact();
    final uri =
        Uri.tryParse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: InkWell(
        onTap: _launch,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_fill,
                size: 56,
                color: Color(0xFFE50914),
              ),
              const SizedBox(height: 8),
              Text(
                'Play Video (${widget.videoId})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.fitFullScreen) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: content,
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? (16 / 9),
        child: content,
      ),
    );
  }
}
