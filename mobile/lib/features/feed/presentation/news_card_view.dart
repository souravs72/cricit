import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/time/story_time.dart';
import '../../../core/widgets/live_pill.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';

/// One full-screen 1-minute read. Layout per DESIGN.md.
class NewsCardView extends StatelessWidget {
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
  });

  final NewsCard card;
  final VoidCallback? onOpenSource;
  final VoidCallback? onPlayVideo;
  final bool saved;
  final VoidCallback? onToggleSave;
  final bool forceHindi;
  final VoidCallback? onToggleLanguage;
  final String? indexLabel;

  Color? get _teamColor {
    for (final tag in card.tags) {
      final c = CricitColors.teams[tag.toLowerCase()];
      if (c != null) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final edge = _teamColor;
    final hindi = forceHindi;
    final headline = card.headlineFor(hindi: hindi);
    final summary = card.summaryFor(hindi: hindi);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return Semantics(
          label: [indexLabel, headline].whereType<String>().join('. '),
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
                SizedBox(
                  height: height * 0.42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (card.image == null)
                        ColoredBox(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: card.image!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.35),
                          ),
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                          ),
                        ),
                      if (card.isVideo)
                        Center(
                          child: IconButton.filled(
                            onPressed: onPlayVideo,
                            icon: const Icon(Icons.play_arrow),
                            tooltip: l10n.playVideo,
                            iconSize: 36,
                          ),
                        ),
                      if (card.isBreaking)
                        const Positioned(
                          left: CricitSpace.md,
                          top: CricitSpace.md,
                          child: LivePill(label: 'Breaking'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CricitSpace.md,
                      CricitSpace.md,
                      CricitSpace.md,
                      CricitSpace.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              storyTimeLabel(card.publishedAt),
                              style: theme.textTheme.labelMedium,
                            ),
                            if (isFresh(card.publishedAt) &&
                                !card.isBreaking) ...[
                              const SizedBox(width: CricitSpace.sm),
                              const LivePill(),
                            ],
                          ],
                        ),
                        const SizedBox(height: CricitSpace.sm),
                        Text(
                          headline,
                          style: theme.textTheme.headlineMedium,
                          maxLines: 3,
                        ),
                        const SizedBox(height: CricitSpace.md),
                        Expanded(
                          child: Text(
                            summary,
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        Row(
                          children: [
                            if (card.sourceName != null)
                              Flexible(
                                child: TextButton(
                                  onPressed: onOpenSource,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: CricitSpace.sm,
                                    ),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: Text(
                                    l10n.readMoreAt(card.sourceName!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            if (card.hasHindi)
                              IconButton(
                                onPressed: onToggleLanguage,
                                tooltip: forceHindi
                                    ? l10n.showEnglish
                                    : l10n.showHindi,
                                icon: const Icon(Icons.translate),
                              ),
                            IconButton(
                              onPressed: () async {
                                await Share.share(
                                  card.shareUrl,
                                  subject: headline,
                                );
                              },
                              tooltip: l10n.shareCard,
                              icon: const Icon(Icons.share_outlined),
                            ),
                            IconButton(
                              onPressed: onToggleSave,
                              tooltip: saved ? l10n.savedCard : l10n.saveCard,
                              icon: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_border,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
