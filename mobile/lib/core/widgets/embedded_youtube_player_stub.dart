import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fallback / mobile stub implementation for embedded YouTube player.
/// Avoids webview_flutter assertion crashes during unit tests and on non-web environments.
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
  Future<void> _launch() async {
    await HapticFeedback.lightImpact();
    final uri = Uri.tryParse('https://www.youtube.com/watch?v=${widget.videoId}');
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
                'Play Video: ${widget.videoId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.fitFullScreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? (16 / 9),
        child: content,
      ),
    );
  }
}
