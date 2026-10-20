import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/news_card.dart';

/// One full-screen 1-minute read. Layout per DESIGN.md: image 42% of height,
/// condensed headline, ~60-word summary, source row; team-colour edge strip.
class NewsCardView extends StatelessWidget {
  const NewsCardView({super.key, required this.card, this.onOpenSource});

  final NewsCard card;
  final VoidCallback? onOpenSource;

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
    final height = MediaQuery.sizeOf(context).height;
    final edge = _teamColor;

    return Semantics(
      label: card.headline,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: edge == null ? null : Border(left: BorderSide(color: edge, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height * 0.42,
              child: card.image == null
                  ? ColoredBox(color: theme.colorScheme.primary.withValues(alpha: 0.12))
                  : CachedNetworkImage(imageUrl: card.image!, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.headline, style: theme.textTheme.headlineMedium, maxLines: 3),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        card.summary,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    if (card.sourceName != null)
                      TextButton(
                        onPressed: onOpenSource,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text('Read more at ${card.sourceName}'),
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
