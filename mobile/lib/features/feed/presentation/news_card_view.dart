import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/time/story_time.dart';
import '../../../core/widgets/embedded_youtube_player.dart';
import '../../../core/widgets/in_app_web_sheet.dart';
import '../../../core/widgets/live_pill.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';
import 'ad_views.dart';
import 'video_short_view.dart';

/// Full-screen 1-minute read card with embedded in-app YouTube player.
/// Videos and articles run completely inside the CRICIT app. External YouTube
/// is only opened when the user explicitly taps "Watch on YouTube ↗".
class NewsCardView extends StatefulWidget {
  const NewsCardView({
    super.key,
    required this.card,
    this.onOpenSource,
    this.onPlayVideo,
    this.saved = false,
    this.onToggleSave,
    this.forceHindi = false,
    this.onToggleLanguage,
    this.indexLabel,
    this.showFooterAd = false,
  });

  final NewsCard card;
  final VoidCallback? onOpenSource;
  final VoidCallback? onPlayVideo;
  final bool saved;
  final VoidCallback? onToggleSave;
  final bool forceHindi;
  final VoidCallback? onToggleLanguage;
  final String? indexLabel;
  final bool showFooterAd;

  @override
  State<NewsCardView> createState() => _NewsCardViewState();
}

class _NewsCardViewState extends State<NewsCardView> {
  bool _isPlayingVideo = false;

  Color? get _teamColor {
    for (final tag in widget.card.tags) {
      final c = CricitColors.teams[tag.toLowerCase()];
      if (c != null) return c;
    }
    return null;
  }

  void _handleOpenSource(BuildContext context) {
    if (widget.onOpenSource != null) {
      widget.onOpenSource!();
    } else if (widget.card.url != null) {
      InAppWebSheet.show(
        context,
        url: widget.card.url!,
        sourceName: widget.card.sourceName ?? 'CRICIT',
        headline: widget.card.headlineFor(hindi: widget.forceHindi),
      );
    }
  }

  Future<void> _openExternalYouTube() async {
    await HapticFeedback.lightImpact();
    final url = widget.card.url ??
        (widget.card.videoId != null
            ? 'https://www.youtube.com/watch?v=${widget.card.videoId}'
            : null);
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final edge = _teamColor;
    final hindi = widget.forceHindi;
    final headline = card.headlineFor(hindi: hindi);
    final summary = card.summaryFor(hindi: hindi);
    final isDark = theme.brightness == Brightness.dark;

    // In video tab or pure video card with no summary, render rich VideoShortView
    if (card.isVideo && summary.isEmpty) {
      return VideoShortView(
        card: card,
        saved: widget.saved,
        onToggleSave: widget.onToggleSave,
        indexLabel: widget.indexLabel,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        return Semantics(
          label: [widget.indexLabel, headline].whereType<String>().join('. '),
          child: Material(
            color: theme.colorScheme.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: edge == null
                    ? null
                    : Border(left: BorderSide(color: edge, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Media Canvas (42% height)
                  SizedBox(
                    height: height * 0.42,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // If embedded video is playing, render in-app YouTube player
                        if (card.isVideo && card.videoId != null && _isPlayingVideo) ...[
                          EmbeddedYouTubePlayer(
                            videoId: card.videoId!,
                            aspectRatio: 16 / 9,
                            autoPlay: true,
                            showControls: true,
                            interactive: true,
                          ),
                          // Compact Close Video control to return to thumbnail
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Semantics(
                              button: true,
                              label: 'Close video player',
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  shape: const CircleBorder(),
                                  elevation: 3,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _isPlayingVideo = false);
                                    },
                                    customBorder: const CircleBorder(),
                                    child: const Center(
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: card.isVideo
                                ? () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isPlayingVideo = true);
                                  }
                                : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (card.image == null && card.videoId == null)
                                  ColoredBox(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    child: Center(
                                      child: Icon(
                                        Icons.sports_cricket,
                                        size: 48,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  )
                                else
                                  CachedNetworkImage(
                                    imageUrl: card.image ??
                                        'https://i.ytimg.com/vi/${card.videoId}/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => ColoredBox(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                    errorWidget: (_, __, ___) => ColoredBox(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                      child: const Center(
                                        child: Icon(Icons.sports_cricket, size: 48),
                                      ),
                                    ),
                                  ),

                                // Vignette gradient for top badges (pass-through touch)
                                IgnorePointer(
                                  ignoring: true,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.45),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.2),
                                        ],
                                        stops: const [0.0, 0.35, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // Video Play Button Overlay - Plays EMBEDDED inside the app!
                                if (card.isVideo)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(CricitRadius.full),
                                        border: Border.all(color: Colors.white38, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Play in App',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Top Badges & Live Pill (pass-through touch so video plays smoothly)
                        if (!_isPlayingVideo)
                          Positioned(
                            left: CricitSpace.md,
                            top: 36.0,
                            child: IgnorePointer(
                              ignoring: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (card.isBreaking)
                                    const LivePill(label: 'Breaking')
                                  else if (card.kind == 'nxtspot')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: CricitSpace.sm,
                                        vertical: CricitSpace.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E),
                                        borderRadius: BorderRadius.circular(CricitRadius.full),
                                      ),
                                      child: const Text(
                                        'Nxtspot',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (isFresh(card.publishedAt))
                                    const LivePill(label: 'Live'),
                                ],
                              ),
                            ),
                          ),

                        // Category pill on top right
                        Positioned(
                          right: CricitSpace.md,
                          top: 36.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(CricitRadius.sm),
                            ),
                            child: Text(
                              card.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Body (Headline, Summary, Actions)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CricitSpace.md,
                        CricitSpace.md,
                        CricitSpace.md,
                        CricitSpace.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timestamp and fresh status
                          Row(
                            children: [
                              Text(
                                storyTimeLabel(card.publishedAt),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark ? CricitColors.inkMutedDark : CricitColors.inkMuted,
                                ),
                              ),
                              if (isFresh(card.publishedAt) && !card.isBreaking) ...[
                                const SizedBox(width: CricitSpace.sm),
                                const LivePill(),
                              ],
                            ],
                          ),
                          const SizedBox(height: CricitSpace.sm),

                          // Headline Hook
                          Text(
                            headline,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: hindi ? CricitFonts.hindi : CricitFonts.display,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: CricitSpace.sm),

                          // 60-Word Story Summary
                          Expanded(
                            child: Text(
                              summary,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: hindi ? CricitFonts.hindi : CricitFonts.body,
                                height: 1.55,
                                letterSpacing: 0.05,
                                color: isDark ? CricitColors.inkDark : CricitColors.ink,
                              ),
                              overflow: TextOverflow.fade,
                            ),
                          ),

                          // Bottom Action Strip
                          Row(
                            children: [
                              // For written news: opens In-App Web Reader modal sheet (stays in app)
                              if (card.sourceName != null && !card.isVideo)
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: () => _handleOpenSource(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: CricitSpace.xs,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      foregroundColor: theme.colorScheme.primary,
                                    ),
                                    icon: const Icon(Icons.public, size: 14),
                                    label: Text(
                                      l10n.readMoreAt(card.sourceName!),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                              // For videos: explicit button to go to YouTube ONLY when user chooses
                              else if (card.isVideo)
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: _openExternalYouTube,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: CricitSpace.xs,
                                      ),
                                      foregroundColor: const Color(0xFFE50914),
                                    ),
                                    icon: const Icon(Icons.open_in_new, size: 14),
                                    label: const Text(
                                      'Watch on YouTube ↗',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),

                              // Language toggle (English / Hindi)
                              if (card.hasHindi)
                                IconButton(
                                  onPressed: widget.onToggleLanguage,
                                  tooltip: hindi ? l10n.showEnglish : l10n.showHindi,
                                  icon: Icon(
                                    Icons.translate,
                                    color: hindi ? theme.colorScheme.primary : null,
                                  ),
                                ),

                              // Share Action
                              IconButton(
                                onPressed: () async {
                                  await HapticFeedback.lightImpact();
                                  await Share.share(
                                    '${card.headline}\n\nRead the 1-minute cricket story on CRICIT: ${card.shareUrl}',
                                    subject: headline,
                                  );
                                },
                                tooltip: l10n.shareCard,
                                icon: const Icon(Icons.share_outlined),
                              ),

                              // Save Bookmark Action
                              IconButton(
                                onPressed: () async {
                                  await HapticFeedback.selectionClick();
                                  widget.onToggleSave?.call();
                                },
                                tooltip: widget.saved ? l10n.savedCard : l10n.saveCard,
                                icon: Icon(
                                  widget.saved ? Icons.bookmark : Icons.bookmark_border,
                                  color: widget.saved ? CricitColors.scoreboard : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inshorts-style Docked Footer Banner Ad
                  if (widget.showFooterAd)
                    const FooterAdBanner(
                      advertiser: 'Dell Technologies',
                      headline: 'Meet the New Dell XPS 13 Powered by Intel',
                      clickUrl: 'https://www.dell.com',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
