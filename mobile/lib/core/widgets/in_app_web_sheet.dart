import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';

/// Inshorts-style In-App Web Article Viewer.
/// Opens when user taps the source credit or swipes to read original article.
class InAppWebSheet extends StatelessWidget {
  const InAppWebSheet({
    super.key,
    required this.url,
    required this.sourceName,
    required this.headline,
  });

  final String url;
  final String sourceName;
  final String headline;

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String sourceName,
    required String headline,
  }) async {
    await HapticFeedback.lightImpact();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InAppWebSheet(
        url: url,
        sourceName: sourceName,
        headline: headline,
      ),
    );
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CricitSpace.md,
              vertical: CricitSpace.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close reader',
                ),
                const SizedBox(width: CricitSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sourceName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ORIGINAL ARTICLE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'Open in Chrome/Browser',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Article preview body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(CricitSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(CricitSpace.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CricitColors.surfaceDark
                          : CricitColors.sightscreen,
                      borderRadius: BorderRadius.circular(CricitRadius.md),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: CricitColors.success,
                        ),
                        SizedBox(width: CricitSpace.sm),
                        Expanded(
                          child: Text(
                            'Verified source publication. CRICIT credits and links directly to official reporting.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CricitSpace.lg),
                  Text(
                    headline,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: CricitSpace.md),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          sourceName.isNotEmpty ? sourceName[0] : 'C',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: CricitSpace.sm),
                      Text(
                        'Reported by $sourceName',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CricitSpace.xl),
                  Text(
                    'To read the full-length interactive coverage, match scorecard, in-depth player statistics, and photo gallery, visit the live article on $sourceName.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: CricitSpace.xl),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _openExternal,
                      style: FilledButton.styleFrom(
                        backgroundColor: CricitColors.outfield,
                        foregroundColor: CricitColors.onOutfield,
                        padding: const EdgeInsets.symmetric(
                          horizontal: CricitSpace.xl,
                          vertical: CricitSpace.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CricitRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.launch, size: 18),
                      label: Text('Read Full Article on $sourceName'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
