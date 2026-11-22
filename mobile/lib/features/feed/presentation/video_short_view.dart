import 'dart:async';
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
/// The embedded YouTube player fills 100% of the screen height and width (edge-to-edge).
/// Videos autoplay automatically when active and pause immediately when scrolled away.
/// The next 2 upcoming videos are preloaded in the background for zero-latency switching.
/// Supports double-tap to toggle between Reel Fill (full bleed) and Fit Video (contain).
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
    this.isActive = true,
    this.isPreload = false,
  });

  final NewsCard card;
  final bool saved;
  final VoidCallback? onToggleSave;
  final String? indexLabel;
  final VoidCallback? onSwipeNext;
  final VoidCallback? onSwipePrevious;
  final bool isActive;
  final bool isPreload;

  @override
  State<VideoShortView> createState() => _VideoShortViewState();
}

class _VideoShortViewState extends State<VideoShortView> {
  bool _userPaused = false;
  bool _liked = false;
  bool _coverMode = true;
  String? _modeBadgeMessage;
  Timer? _badgeTimer;
  double _dragDeltaX = 0;
  double _dragDeltaY = 0;

  @override
  void didUpdateWidget(VideoShortView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (!widget.isActive) {
        _userPaused = false;
      }
    }
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() => _userPaused = !_userPaused);
  }

  void _toggleCoverMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _coverMode = !_coverMode;
      _modeBadgeMessage = _coverMode ? 'Reel Fill (Full Bleed)' : 'Fit Video (Uncropped)';
    });
    _badgeTimer?.cancel();
    _badgeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _modeBadgeMessage = null);
    });
  }

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

  void _handleVerticalDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0;
    if (_dragDeltaY < -30 || vy < -100) {
      HapticFeedback.lightImpact();
      widget.onSwipeNext?.call();
    } else if (_dragDeltaY > 30 || vy > 100) {
      HapticFeedback.lightImpact();
      widget.onSwipePrevious?.call();
    }
    _dragDeltaY = 0;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final videoId = card.videoId ?? 'xtn0lf5TY84';
    final hasSwipeCallbacks =
        widget.onSwipeNext != null || widget.onSwipePrevious != null;

    final isShort = (card.url != null && card.url!.contains('/shorts/')) ||
        card.tags.any((t) => t.toLowerCase().contains('short')) ||
        card.kind == 'video';
    final videoRatio = isShort ? (9 / 16) : (16 / 9);
    final isActuallyPlaying = widget.isActive && !_userPaused;

    Widget content = Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Height & Width Video Canvas (100% full-bleed edge-to-edge reel)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _togglePlayPause,
              onDoubleTap: _toggleCoverMode,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EmbeddedYouTubePlayer(
                    key: ValueKey('yt-${card.id}-${card.videoId}'),
                    videoId: videoId,
                    aspectRatio: videoRatio,
                    fitFullScreen: true,
                    coverMode: _coverMode,
                    autoPlay: true,
                    showControls: false,
                    interactive: true,
                    isActive: isActuallyPlaying,
                    isPreload: widget.isPreload,
                  ),
                  if (widget.isActive && _userPaused)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 48,
                          color: Colors.white,
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

          // 4. Top Right Floating Toggle: [ ⛶ Reel Fill / ⊡ Fit Video ]
          Positioned(
            top: 44,
            right: CricitSpace.md,
            child: Semantics(
              button: true,
              label: _coverMode ? 'Switch to uncropped fit' : 'Switch to full bleed reel',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleCoverMode,
                  borderRadius: BorderRadius.circular(CricitRadius.full),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(CricitRadius.full),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _coverMode
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _coverMode ? 'Reel Fill' : 'Fit Video',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Transient Mode Feedback Badge (fades after double-tap / tap toggle)
          if (_modeBadgeMessage != null)
            Center(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _modeBadgeMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(CricitRadius.full),
                      border: Border.all(color: Colors.white38),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _coverMode
                              ? Icons.crop_free_rounded
                              : Icons.aspect_ratio_rounded,
                          color: CricitColors.scoreboard,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _modeBadgeMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 6. Right Floating Action Column (Reels / Shorts Style)
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
                  icon: widget.saved ? Icons.bookmark : Icons.bookmark_border,
                  color: widget.saved ? CricitColors.scoreboard : Colors.white,
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

          // 7. Bottom Metadata Overlay (Left aligned)
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
        onVerticalDragStart: (_) => _dragDeltaY = 0,
        onVerticalDragUpdate: (details) => _dragDeltaY += details.delta.dy,
        onVerticalDragEnd: _handleVerticalDragEnd,
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
