import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/l10n.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/data/fixture_feed.dart';
import '../../feed/domain/news_card.dart';
import '../../feed/presentation/news_card_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _query = '';
  var _loading = false;
  List<NewsCard> _results = const [];

  static const _chips = ['India', 'Bumrah', 'IPL', 'WPL', 'Nxtspot'];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String value) async {
    setState(() {
      _query = value.trim();
      _loading = _query.isNotEmpty;
    });
    if (_query.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final lang = ref.read(settingsProvider).language;
    final found =
        await ref.read(feedRepositoryProvider).search(_query, lang: lang);
    if (!mounted) return;
    setState(() {
      _results = found;
      _loading = false;
    });
  }

  Future<void> _openCard(NewsCard card) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final settings = ref.read(settingsProvider);
          return Scaffold(
            appBar: AppBar(),
            body: NewsCardView(
              card: card,
              saved: settings.bookmarks.contains(card.id),
              forceHindi: settings.isHindi,
              onToggleSave: () =>
                  ref.read(settingsProvider.notifier).toggleBookmark(card.id),
              onOpenSource: card.url == null
                  ? null
                  : () async {
                      await launchUrl(
                        Uri.parse(card.url!),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final nxtspot = fixtureCards().where((c) => c.kind == 'nxtspot').toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CricitSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.searchLabel,
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: CricitSpace.md),
            if (_query.isEmpty) ...[
              Text(
                l10n.trending,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: CricitSpace.sm),
              Wrap(
                spacing: CricitSpace.sm,
                runSpacing: CricitSpace.sm,
                children: [
                  for (final chip in _chips)
                    ActionChip(
                      label: Text(chip),
                      onPressed: () {
                        _controller.text = chip;
                        _search(chip);
                      },
                    ),
                ],
              ),
              const SizedBox(height: CricitSpace.lg),
              Text(
                l10n.tabNxtspot,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: CricitSpace.sm),
              ...nxtspot.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.headline),
                  subtitle: Text(c.sourceName ?? l10n.tabNxtspot),
                  onTap: () => _openCard(c),
                ),
              ),
            ] else if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: CricitSpace.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_results.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: l10n.noResults,
                  body: l10n.noResultsBody,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final card = _results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(card.headline),
                      subtitle: Text(card.sourceName ?? card.category),
                      onTap: () => _openCard(card),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
