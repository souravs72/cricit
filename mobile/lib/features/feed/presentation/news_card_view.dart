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
import '../../../core/widgets/youtube_poster.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';
import 'ad_views.dart';
import 'video_short_view.dart';

/// The one-minute read: picture header, headline hook, ~60-word summary,
/// media-house credit and a link to the original article (brief, p.1).
///
/// Motion is driven by the swipe, never by page load: [parallax] drifts the
/// picture against the swipe and [settle] brings the text in as the card
/// lands. Both are identity at rest and are ignored under reduced motion.
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
    this.parallax = 0,
    this.settle = 1,
  });

  final NewsCard card;
  final VoidCallback? onOpenSource;
  final VoidCallback? onPlayVideo;
  final bool saved;
  final VoidCallback? onToggleSave;
  final bool forceHindi;
  final VoidCallback? onToggleLanguage;
  final String? indexLabel;

  /// Show a house footer banner even when the card has no [NewsCard.footerAd].
  final bool showFooterAd;

  /// -1..1, the card's page offset while a swipe is in flight.
  final double parallax;

  /// 0..1, how settled the card is on screen.
  final double settle;

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
    HapticFeedback.lightImpact();
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
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final hindi = widget.forceHindi;
    final headline = card.headlineFor(hindi: hindi);
    final summary = card.summaryFor(hindi: hindi);
    final muted = theme.colorScheme.onSurfaceVariant;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final settle = reduceMotion ? 1.0 : widget.settle.clamp(0.0, 1.0);
    final parallax = reduceMotion ? 0.0 : widget.parallax.clamp(-1.0, 1.0);

    if (card.isVideo && summary.isEmpty) {
      return VideoShortView(
        card: card,
        saved: widget.saved,
        onToggleSave: widget.onToggleSave,
        indexLabel: widget.indexLabel,
      );
    }

    final edge = _teamColor;
    final footerAd = card.footerAd;

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
                border: edge == null
                    ? null
                    : Border(left: BorderSide(color: edge, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height * 0.42,
                    child: _isPlayingVideo && card.videoId != null
                        ? _InlinePlayer(
                            videoId: card.videoId!,
                            onClose: () =>
                                setState(() => _isPlayingVideo = false),
                          )
                        : _Hero(
                            card: card,
                            parallax: parallax,
                            onPlay: card.isVideo
                                ? () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isPlayingVideo = true);
                                  }
                                : null,
                          ),
                  ),
                  Expanded(
                    child: _Settle(
                      progress: settle,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          CricitSpace.md,
                          CricitSpace.md,
                          CricitSpace.md,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SourceRow(
                              card: card,
                              hindi: hindi,
                              onToggleLanguage: widget.onToggleLanguage,
                            ),
                            const SizedBox(height: CricitSpace.sm + 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                headline,
                                key: ValueKey('h-$hindi'),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: hindi
                                      ? CricitFonts.hindi
                                      : CricitFonts.display,
                                  height: hindi ? 1.35 : 1.12,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: CricitSpace.sm + 2),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Align(
                                  key: ValueKey('s-$hindi'),
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    summary,
                                    style: theme.textTheme.bodyLarge,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            SizedBox(
                              height: CricitSpace.xxl + CricitSpace.xs,
                              child: Row(
                                children: [
                                  if (card.isVideo)
                                    Flexible(
                                      child: _SourceLink(
                                        label: l10n.watchOnYouTube,
                                        icon: Icons.play_circle_outline,
                                        onTap: _openExternalYouTube,
                                      ),
                                    )
                                  else if (card.url != null)
                                    Flexible(
                                      child: _SourceLink(
                                        label: l10n.readMoreAt(
                                          card.sourceName ?? 'source',
                                        ),
                                        icon: Icons.north_east_rounded,
                                        onTap: () => _handleOpenSource(context),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  const SizedBox(width: CricitSpace.xs),
                                  IconButton(
                                    onPressed: () async {
                                      await HapticFeedback.lightImpact();
                                      await Share.share(
                                        '$headline\n\n${l10n.shareText(card.shareUrl)}',
                                        subject: headline,
                                      );
                                    },
                                    tooltip: l10n.shareCard,
                                    color: muted,
                                    icon: const Icon(Icons.ios_share_rounded),
                                  ),
                                  SaveButton(
                                    saved: widget.saved,
                                    onToggle: widget.onToggleSave,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (footerAd != null)
                    FooterAdBanner.fromSlot(footerAd)
                  else if (widget.showFooterAd)
                    const FooterAdBanner(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Picture header. Status pill (breaking / Nxtspot / live) on the left,
/// section on the right; each pill carries its own background so no gradient
/// wash is needed for legibility.
class _Hero extends StatelessWidget {
  const _Hero({required this.card, required this.parallax, this.onPlay});

  final NewsCard card;
  final double parallax;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final imageUrl = card.image ??
        (card.videoId != null ? youTubePosterUrl(card.videoId!) : null);
    final placeholder = ColoredBox(
      color: theme.colorScheme.primary.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          Icons.sports_cricket,
          size: 48,
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );

    final section = switch (card.category) {
      'domestic' => l10n.tabDomestic,
      'international' => l10n.tabInternational,
      'grassroots' => l10n.tabNxtspot,
      _ => null,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPlay,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Over-scaled so the drift never shows an edge.
            Transform.translate(
              offset: Offset(0, parallax * 28),
              child: Transform.scale(
                scale: 1.12,
                child: imageUrl == null
                    ? placeholder
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 180),
                        placeholder: (_, __) => ColoredBox(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.25),
                        ),
                        errorWidget: (_, __, ___) => placeholder,
                      ),
              ),
            ),
            if (onPlay != null)
              Center(
                child: _GlassPill(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CricitSpace.md + 2,
                    vertical: CricitSpace.sm + 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: CricitSpace.xs + 2),
                      Text(
                        'Play in App',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: CricitSpace.md,
              right: CricitSpace.md,
              top: CricitSpace.xl + CricitSpace.xs,
              child: IgnorePointer(
                child: Row(
                  children: [
                    if (card.isBreaking)
                      _SolidPill(
                        color: CricitColors.ball,
                        label: l10n.breaking,
                        icon: Icons.bolt_rounded,
                      )
                    else if (card.kind == 'nxtspot' ||
                        card.category == 'grassroots')
                      _SolidPill(
                        color: CricitColors.outfield,
                        label: l10n.tabNxtspot,
                        icon: Icons.auto_awesome_rounded,
                      )
                    else if (isFresh(card.publishedAt))
                      LivePill(label: l10n.justIn),
                    const Spacer(),
                    if (section != null &&
                        card.kind != 'nxtspot' &&
                        card.category != 'grassroots')
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CricitSpace.sm + 2,
                          vertical: CricitSpace.xs,
                        ),
                        child: Text(
                          section,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlinePlayer extends StatelessWidget {
  const _InlinePlayer({required this.videoId, required this.onClose});

  final String videoId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        EmbeddedYouTubePlayer(
          videoId: videoId,
          aspectRatio: 16 / 9,
          autoPlay: true,
          showControls: true,
          interactive: true,
        ),
        Positioned(
          top: CricitSpace.sm,
          right: CricitSpace.sm,
          child: Semantics(
            button: true,
            label: 'Close video player',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.black.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onClose();
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Media-house credit line: monogram, source, time, and the EN/हिं switch.
class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.card,
    required this.hindi,
    this.onToggleLanguage,
  });

  final NewsCard card;
  final bool hindi;
  final VoidCallback? onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final source = card.sourceName ?? 'CRICIT';
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        SourceMonogram(name: source),
        const SizedBox(width: CricitSpace.sm),
        Flexible(
          child: Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '  ·  ${storyTimeLabel(card.publishedAt)}',
          style: theme.textTheme.labelMedium?.copyWith(color: muted),
        ),
        const Spacer(),
        if (card.hasHindi && onToggleLanguage != null)
          Semantics(
            button: true,
            label: hindi ? l10n.showEnglish : l10n.showHindi,
            child: Tooltip(
              message: hindi ? l10n.showEnglish : l10n.showHindi,
              child: _LanguageToggle(hindi: hindi, onTap: onToggleLanguage!),
            ),
          ),
      ],
    );
  }
}

/// Two-segment EN | हिं switch whose thumb slides to the active language.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.hindi, required this.onTap});

  final bool hindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const w = 34.0;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 28,
        width: w * 2 + 6,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CricitRadius.full),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: hindi ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: w,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(CricitRadius.full),
                ),
              ),
            ),
            Row(
              children: [
                for (final (label, on) in [('EN', !hindi), ('हिं', hindi)])
                  SizedBox(
                    width: w,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily:
                              label == 'EN' ? CricitFonts.body : CricitFonts.hindi,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Read more at …" link with an arrow that nudges toward the source on press.
class _SourceLink extends StatefulWidget {
  const _SourceLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SourceLink> createState() => _SourceLinkState();
}

class _SourceLinkState extends State<_SourceLink> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (v) => setState(() => _pressed = v),
      borderRadius: BorderRadius.circular(CricitRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CricitSpace.xs,
          vertical: CricitSpace.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: CricitSpace.xs),
            AnimatedSlide(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              offset: _pressed ? const Offset(0.25, -0.25) : Offset.zero,
              child: Icon(widget.icon, size: 16, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bookmark with a small pop when saved. Shared by cards and search results.
class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.saved, this.onToggle});

  final bool saved;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onToggle == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onToggle!();
            },
      tooltip: saved ? l10n.savedCard : l10n.saveCard,
      icon: TweenAnimationBuilder<double>(
        key: ValueKey(saved),
        tween: Tween(begin: saved ? 0.6 : 1, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: saved
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Round initial badge standing in for a media-house logo.
class SourceMonogram extends StatelessWidget {
  const SourceMonogram({super.key, required this.name, this.size = 22});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: CricitFonts.display,
          fontSize: size * 0.55,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1,
        ),
      ),
    );
  }
}

class _SolidPill extends StatelessWidget {
  const _SolidPill({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CricitSpace.sm + 2,
        vertical: CricitSpace.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(CricitRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: CricitColors.onOutfield),
            const SizedBox(width: CricitSpace.xs),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: CricitFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CricitColors.onOutfield,
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent dark pill for labels that sit on photos.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(CricitRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

/// Fades and lifts content in as a card settles. Same tree at every value.
class _Settle extends StatelessWidget {
  const _Settle({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    return Opacity(
      opacity: 0.35 + 0.65 * t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 18),
        child: child,
      ),
    );
  }
}
