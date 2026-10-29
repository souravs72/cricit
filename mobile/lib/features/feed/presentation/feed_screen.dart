import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';
import 'feed_controller.dart';
import 'news_card_view.dart';

const _tabs = ['feed', 'video', 'domestic', 'international', 'nxtspot'];

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.openCardId});

  final String? openCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final labels = [
      l10n.tabFeed,
      l10n.tabVideo,
      l10n.tabDomestic,
      l10n.tabInternational,
      l10n.tabNxtspot,
    ];
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                isScrollable: true,
                tabs: [for (final l in labels) Tab(text: l)],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final t in _tabs)
                  _TabFeed(tab: t, openCardId: t == 'feed' ? openCardId : null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabFeed extends ConsumerStatefulWidget {
  const _TabFeed({required this.tab, this.openCardId});

  final String tab;
  final String? openCardId;

  @override
  ConsumerState<_TabFeed> createState() => _TabFeedState();
}

class _TabFeedState extends ConsumerState<_TabFeed> {
  final _page = PageController();
  final _hindiOverride = <String, bool>{};
  var _reportedInitialView = false;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _open(NewsCard card) async {
    final uri = card.isVideo && card.videoId != null
        ? Uri.parse('https://www.youtube.com/watch?v=${card.videoId}')
        : card.url == null
            ? null
            : Uri.parse(card.url!);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final snap = ref.watch(feedControllerProvider(widget.tab));
    final ctrl = ref.read(feedControllerProvider(widget.tab).notifier);
    final settings = ref.watch(settingsProvider);

    if (snap.status != FeedStatus.data) {
      _reportedInitialView = false;
    } else if (!_reportedInitialView && snap.cards.isNotEmpty) {
      _reportedInitialView = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final openId = widget.openCardId;
        if (openId != null) {
          final i = snap.cards.indexWhere((c) => c.id == openId);
          if (i >= 0 && _page.hasClients) {
            _page.jumpToPage(i);
            return;
          }
        }
        ctrl.onPageChanged(0);
      });
    }

    Widget body;
    switch (snap.status) {
      case FeedStatus.loading:
        body = const FeedSkeleton();
      case FeedStatus.error:
        body = ErrorState(
          title: l10n.feedLoadError,
          body: snap.errorMessage ?? l10n.feedLoadErrorBody,
          onRetry: ctrl.reload,
        );
      case FeedStatus.empty:
        body = EmptyState(title: l10n.noStories, body: l10n.noStoriesBody);
      case FeedStatus.data:
        body = RefreshIndicator(
          onRefresh: ctrl.refresh,
          child: PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            physics: AlwaysScrollableScrollPhysics(
              parent: MediaQuery.disableAnimationsOf(context)
                  ? const ClampingScrollPhysics()
                  : const PageScrollPhysics(),
            ),
            itemCount: snap.cards.length,
            onPageChanged: ctrl.onPageChanged,
            itemBuilder: (context, i) {
              final card = snap.cards[i];
              final hindi = _hindiOverride[card.id] ?? settings.isHindi;
              return NewsCardView(
                card: card,
                saved: settings.bookmarks.contains(card.id),
                forceHindi: hindi,
                indexLabel: 'Story ${i + 1} of ${snap.cards.length}',
                onOpenSource: card.url == null ? null : () => _open(card),
                onPlayVideo: card.isVideo ? () => _open(card) : null,
                onToggleSave: () =>
                    ref.read(settingsProvider.notifier).toggleBookmark(card.id),
                onToggleLanguage: card.hasHindi
                    ? () => setState(() => _hindiOverride[card.id] = !hindi)
                    : null,
              );
            },
          ),
        );
    }

    return Stack(
      children: [
        body,
        if (snap.fromCache && snap.status == FeedStatus.data)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineBanner(message: l10n.offlineBanner),
          ),
        if (snap.hasNewPosts)
          Positioned(
            top: CricitSpace.md,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.tonal(
                onPressed: () {
                  ctrl.revealNewPosts();
                  if (_page.hasClients) _page.jumpToPage(0);
                },
                child: Text(l10n.newPosts),
              ),
            ),
          ),
      ],
    );
  }
}
