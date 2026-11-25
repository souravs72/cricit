import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';

/// The three ad formats in the brief (p.5): full page, footer under a post,
/// and a short sponsored post. Ads always say "Sponsored" in words, sit on
/// the same surfaces as stories, and open in the in-app browser.
Future<void> _openAd(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return;
  await HapticFeedback.lightImpact();
  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

class _SponsoredTag extends StatelessWidget {
  const _SponsoredTag({this.onDark = false, this.advertiser});

  final bool onDark;
  final String? advertiser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final fg = onDark ? Colors.white : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CricitSpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: onDark ? Colors.black.withValues(alpha: 0.55) : null,
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.3)
              : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(CricitRadius.full),
      ),
      child: Text(
        advertiser == null ? l10n.sponsored : '${l10n.sponsored} · $advertiser',
        style: theme.textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

/// Slim banner docked at the foot of a story. Dismissible for the session.
class FooterAdBanner extends StatefulWidget {
  const FooterAdBanner({
    super.key,
    this.advertiser = 'CRICIT',
    this.headline = 'Get breaking cricket alerts first',
    this.clickUrl = 'https://cricit.app',
  });

  factory FooterAdBanner.fromSlot(AdSlot slot, {Key? key}) => FooterAdBanner(
        key: key,
        advertiser: slot.advertiser ?? 'Sponsor',
        headline: slot.title ?? slot.body ?? '',
        clickUrl: slot.clickUrl,
      );

  final String advertiser;
  final String headline;
  final String clickUrl;

  @override
  State<FooterAdBanner> createState() => _FooterAdBannerState();
}

class _FooterAdBannerState extends State<FooterAdBanner> {
  var _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: _dismissed
          ? const SizedBox(width: double.infinity)
          : Material(
              color: theme.scaffoldBackgroundColor,
              child: InkWell(
                onTap: () => _openAd(widget.clickUrl),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.only(left: CricitSpace.md),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.sponsored} · ${widget.advertiser}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                            Text(
                              widget.headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      IconButton(
                        tooltip: l10n.dismissAd,
                        iconSize: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                        onPressed: () => setState(() => _dismissed = true),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// A whole page in the deck given to one advertiser: creative full bleed,
/// copy on a solid panel at the foot so it reads on any image.
class FullPageAdCard extends StatelessWidget {
  const FullPageAdCard({super.key, required this.slot});

  final AdSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final advertiser = slot.advertiser ?? 'Sponsor';
    return Semantics(
      label: '${l10n.sponsored}. ${slot.title ?? advertiser}',
      child: Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: () => _openAd(slot.clickUrl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (slot.creative != null)
                      CachedNetworkImage(
                        imageUrl: slot.creative!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: CricitColors.outfield),
                      )
                    else
                      const ColoredBox(color: CricitColors.outfield),
                    const Positioned(
                      top: CricitSpace.xl + CricitSpace.xs,
                      left: CricitSpace.md,
                      child: _SponsoredTag(onDark: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CricitSpace.md,
                  CricitSpace.md,
                  CricitSpace.md,
                  CricitSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advertiser,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: CricitSpace.xs),
                    if (slot.title != null)
                      Text(slot.title!, style: theme.textTheme.headlineMedium),
                    if (slot.body != null) ...[
                      const SizedBox(height: CricitSpace.sm),
                      Text(slot.body!, style: theme.textTheme.bodyLarge),
                    ],
                    const SizedBox(height: CricitSpace.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openAd(slot.clickUrl),
                        child: Text(l10n.visitAdvertiser(advertiser)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short post written by a sponsor, laid out like a story so it sits in
/// the deck without jarring, but always labelled as sponsored.
class SponsoredCardView extends StatelessWidget {
  const SponsoredCardView({super.key, required this.slot});

  final AdSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return Material(
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: () => _openAd(slot.clickUrl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: height * 0.42,
                  child: slot.creative == null
                      ? const ColoredBox(color: CricitColors.outfield)
                      : CachedNetworkImage(
                          imageUrl: slot.creative!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: CricitColors.outfield),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(CricitSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SponsoredTag(advertiser: slot.advertiser),
                        const SizedBox(height: CricitSpace.sm + 2),
                        if (slot.title != null)
                          Text(
                            slot.title!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium,
                          ),
                        const SizedBox(height: CricitSpace.sm + 2),
                        if (slot.body != null)
                          Expanded(
                            child: Text(
                              slot.body!,
                              overflow: TextOverflow.fade,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        else
                          const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openAd(slot.clickUrl),
                          icon: const Icon(Icons.north_east_rounded, size: 16),
                          label: Text(l10n.knowMore),
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

/// Picks the right view for an ad page in the deck.
class AdPageView extends StatelessWidget {
  const AdPageView({super.key, required this.slot});

  final AdSlot slot;

  @override
  Widget build(BuildContext context) => slot.isFullPage
      ? FullPageAdCard(slot: slot)
      : SponsoredCardView(slot: slot);
}
