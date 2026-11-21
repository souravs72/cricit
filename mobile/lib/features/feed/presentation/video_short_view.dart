import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/time/story_time.dart';
import '../../../core/widgets/embedded_youtube_player.dart';
import '../domain/news_card.dart';

/// Full-screen height and full-screen width Cricket Video Short card.
/// Designed for immersive, vertical cricket clips (Shorts & Reels style).
/// The embedded YouTube player fills 100% of the screen height and width.
/// Metadata and interactive actions float cleanly on top with a subtle scrim.
/// Fully supports horizontal swipe (swipe left for next, swipe right for previous).
class VideoShortView extends StatefulWidget {
  const VideoShortView({
    super.key,
    required this.card,
    this.saved = false,
    this.onToggleSave,
    this.indexLabel,
    this.onSwipeNext,
    this.onSwipePrevious,
  });

  final NewsCard card;
  final bool saved;
  final VoidCallback? onToggleSave;
  final String? indexLabel;
  final VoidCallback? onSwipeNext;
  final VoidCallback? onSwipePrevious;

  @override
  State<VideoShortView> createState() => _VideoShortViewState();
}

class _VideoShortViewState extends State<VideoShortView> {
  bool _isPlaying = true;
  bool _liked = false;
  double _dragDeltaX = 0;

  Future<void> _openExternalYouTube() async {
    await HapticFeedback.lightImpact();
    final card = widget.card;
    final url = card.url ??
        (card.videoId != null
            ? 'https://www.youtube.com/shorts/${card.videoId}'
            : 'https://www.youtube.com/@cricbuzz/shorts');
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final vx = details.primaryVelocity ?? 0;
    if (_dragDeltaX < -30 || vx < -100) {
      HapticFeedback.lightImpact();
      widget.onSwipeNext?.call();
    } else if (_dragDeltaX > 30 || vx > 100) {
      HapticFeedback.lightImpact();
      widget.onSwipePrevious?.call();
    }
    _dragDeltaX = 0;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final videoId = card.videoId ?? 'xtn0lf5TY84';
    final thumb = card.image ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    final hasSwipeCallbacks =
        widget.onSwipeNext != null || widget.onSwipePrevious != null;

    Widget content = Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Height & Width Video Canvas (100% height and width)
          Positioned.fill(
            child: _isPlaying
                ? EmbeddedYouTubePlayer(
                    videoId: videoId,
                    fitFullScreen: true,
                    autoPlay: true,
                    showControls: true,
                    interactive: true,
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isPlaying = true);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                            color: Color(0xFF0F1713),
                          ),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFF0F1713),
                            child: Center(
                              child: Icon(
                                Icons.videocam_outlined,
                                size: 48,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius:
                                  BorderRadius.circular(CricitRadius.full),
                              border: Border.all(color: Colors.white38, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Play Video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Gesture Scrim: subtle top & bottom dark fades for text legibility (pass-through touch)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.18, 0.60, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Floating Badge: CRICIT VIDEO (pass-through touch)
          Positioned(
            top: 48,
            left: CricitSpace.md,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(CricitRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CRICIT VIDEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

              // 4. Right Floating Action Column (Reels / Shorts Style)
              Positioned(
                right: CricitSpace.md,
                bottom: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like Button
                    _FloatingActionButton(
                      icon: _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? Colors.red : Colors.white,
                      label: _liked ? 'Liked' : 'Like',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _liked = !_liked);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bookmark / Save
                    _FloatingActionButton(
                      icon:
                          widget.saved ? Icons.bookmark : Icons.bookmark_border,
                      color:
                          widget.saved ? CricitColors.scoreboard : Colors.white,
                      label: widget.saved ? 'Saved' : 'Save',
                      onTap: widget.onToggleSave,
                    ),
                    const SizedBox(height: 16),

                    // Share Button
                    _FloatingActionButton(
                      icon: Icons.share_outlined,
                      color: Colors.white,
                      label: 'Share',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Share.share(card.shareUrl, subject: card.headline);
                      },
                    ),
                  ],
                ),
              ),

              // 5. Bottom Metadata Overlay (Left aligned)
              Positioned(
                left: CricitSpace.md,
                right: 80,
                bottom: CricitSpace.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Channel Pill & Relative Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(CricitRadius.full),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                radius: 7,
                                backgroundColor: Color(0xFFE50914),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 9,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                card.sourceName ?? 'Cricbuzz',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 11,
                                color: Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          storyTimeLabel(card.publishedAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Headline
                    Text(
                      card.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: CricitFonts.display,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),

                    // Summary / Narrative Description
                    if (card.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Explicit "Watch on YouTube ↗" pill button
                    OutlinedButton.icon(
                      onPressed: _openExternalYouTube,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Colors.white38),
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(CricitRadius.full),
                        ),
                      ),
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 12,
                        color: Color(0xFFE50914),
                      ),
                      label: const Text(
                        'Watch on YouTube ↗',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    if (hasSwipeCallbacks) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _dragDeltaX = 0,
        onHorizontalDragUpdate: (details) => _dragDeltaX += details.delta.dx,
        onHorizontalDragEnd: _handleDragEnd,
        child: content,
      );
    }

    return Semantics(
      label: [widget.indexLabel, card.headline].whereType<String>().join('. '),
      child: content,
    );
  }
}

/// Compact floating button for Likes, Saves, and Shares in full-screen video mode.
class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
