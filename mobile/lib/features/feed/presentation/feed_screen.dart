import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/feed_repository.dart';
import 'news_card_view.dart';

const _tabs = ['feed', 'video', 'domestic', 'international', 'nxtspot'];
const _labels = ['My Feed', 'Video', 'Domestic', 'International', 'Nxtspot'];

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final l in _labels) Tab(text: l)],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // vertical swipe owns the gesture
          children: [for (final t in _tabs) _TabFeed(tab: t)],
        ),
      ),
    );
  }
}

class _TabFeed extends ConsumerWidget {
  const _TabFeed({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab == 'video') {
      return const Center(child: Text('Video shorts arrive in T29.'));
    }
    final page = ref.watch(feedProvider(tab));
    return page.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        title: 'Couldn’t load the feed',
        body: 'Check your connection, then pull down to try again.',
        onRetry: () => ref.invalidate(feedProvider(tab)),
      ),
      data: (p) => p.cards.isEmpty
          ? const _Message(title: 'No stories yet', body: 'New cards appear here as soon as they publish.')
          : RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider(tab).future),
              child: PageView.builder(
                scrollDirection: Axis.vertical, // swipe up/down, not scroll (brief)
                itemCount: p.cards.length,
                itemBuilder: (context, i) {
                  final card = p.cards[i];
                  return NewsCardView(
                    card: card,
                    onOpenSource: card.url == null
                        ? null
                        : () => launchUrl(Uri.parse(card.url!), mode: LaunchMode.inAppBrowserView),
                  );
                },
              ),
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.onRetry});

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: t.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: t.bodyLarge, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
