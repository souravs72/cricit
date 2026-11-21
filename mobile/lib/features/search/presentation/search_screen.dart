import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/in_app_web_sheet.dart';
import '../../../core/widgets/live_pill.dart';
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

  static const _chips = [
    'India',
    'Bumrah',
    'IPL 2026',
    'WPL',
    'Nxtspot',
    'Kohli',
    'Ranji Trophy',
  ];

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

  void _showTriviaDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _CricketTriviaSheet(),
    );
  }

  Future<void> _openCard(NewsCard card) async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final settings = ref.read(settingsProvider);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                card.category.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            body: NewsCardView(
              card: card,
              saved: settings.bookmarks.contains(card.id),
              forceHindi: settings.isHindi,
              onToggleSave: () =>
                  ref.read(settingsProvider.notifier).toggleBookmark(card.id),
              onOpenSource: card.url == null
                  ? null
                  : () => InAppWebSheet.show(
                        context,
                        url: card.url!,
                        sourceName: card.sourceName ?? 'CRICIT',
                        headline: card.headline,
                      ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allFixtures = fixtureCards();
    final nxtspot = allFixtures.where((c) => c.kind == 'nxtspot').toList();
    final notifications = allFixtures.take(3).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar Input
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CricitSpace.md,
              CricitSpace.md,
              CricitSpace.md,
              CricitSpace.sm,
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.searchLabel,
                hintText: 'Search cricket news, teams, players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? CricitColors.surfaceDark
                    : CricitColors.sightscreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CricitRadius.md),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CricitRadius.md),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),

          // Main Search or Discover Content
          Expanded(
            child: _query.isNotEmpty
                ? _buildSearchResults(l10n)
                : _buildDiscoverFeed(l10n, theme, isDark, notifications, nxtspot),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverFeed(
    L10n l10n,
    ThemeData theme,
    bool isDark,
    List<NewsCard> notifications,
    List<NewsCard> nxtspot,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: CricitSpace.md),
      children: [
        const SizedBox(height: CricitSpace.xs),

        // Inshorts Word Wheel / Daily Trivia widget (interactive daily trivia)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTriviaDialog(context),
            borderRadius: BorderRadius.circular(CricitRadius.md),
            child: Container(
              padding: const EdgeInsets.all(CricitSpace.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1B3827), const Color(0xFF0F2419)]
                      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(CricitRadius.md),
                border: Border.all(
                  color: CricitColors.outfield.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: CricitColors.scoreboard,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_cricket,
                      size: 22,
                      color: CricitColors.ink,
                    ),
                  ),
                  const SizedBox(width: CricitSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'CRICKET WORD WHEEL',
                              style: TextStyle(
                                fontFamily: CricitFonts.display,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'DAILY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: CricitColors.outfield,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Play today’s 1-min trivia: Test your cricket IQ & earn fan streaks!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : CricitColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: CricitSpace.md),

        // Trending Topics Chips
        Text(
          l10n.trending,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: CricitSpace.sm),
        Wrap(
          spacing: CricitSpace.sm,
          runSpacing: CricitSpace.xs,
          children: [
            for (final chip in _chips)
              ActionChip(
                label: Text(chip),
                avatar: const Icon(Icons.trending_up, size: 14),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _controller.text = chip;
                  _search(chip);
                },
              ),
          ],
        ),
        const SizedBox(height: CricitSpace.lg),

        // Breaking News & Notifications section (from Page 7 screenshot)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NOTIFICATIONS & BREAKING',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const LivePill(label: 'Live'),
          ],
        ),
        const SizedBox(height: CricitSpace.sm),
        ...notifications.map((card) => _buildNotificationTile(card)),

        const SizedBox(height: CricitSpace.lg),

        // Nxtspot Grassroots Spotlight Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NXTSPOT GRASSROOTS DISCOVERIES',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: const Color(0xFF0F766E),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EXCLUSIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CricitSpace.sm),
        ...nxtspot.map((c) => _buildNxtspotTile(c)),
        const SizedBox(height: CricitSpace.xl),
      ],
    );
  }

  Widget _buildNotificationTile(NewsCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: CricitSpace.sm),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CricitRadius.md),
      ),
      child: ListTile(
        onTap: () => _openCard(card),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(CricitRadius.sm),
          child: card.image != null
              ? Image.network(
                  card.image!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Colors.grey,
                    child: Icon(Icons.sports_cricket, size: 20),
                  ),
                )
              : const ColoredBox(
                  color: Colors.grey,
                  child: Icon(Icons.sports_cricket, size: 20),
                ),
        ),
        title: Text(
          card.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${card.sourceName ?? "CRICIT"} · ${card.category}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      ),
    );
  }

  Widget _buildNxtspotTile(NewsCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: CricitSpace.sm),
      elevation: 0,
      color: const Color(0xFF0F766E).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CricitRadius.md),
        side: BorderSide(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () => _openCard(card),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(CricitRadius.sm),
          child: card.image != null
              ? Image.network(
                  card.image!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF0F766E),
                    child: Icon(Icons.star, color: Colors.white, size: 20),
                  ),
                )
              : const ColoredBox(
                  color: Color(0xFF0F766E),
                  child: Icon(Icons.star, color: Colors.white, size: 20),
                ),
        ),
        title: Text(
          card.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Nxtspot · Grassroots Cricket',
          style: TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      ),
    );
  }

  Widget _buildSearchResults(L10n l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noResults,
        body: l10n.noResultsBody,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(CricitSpace.md),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final card = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(CricitRadius.sm),
            child: card.image != null
                ? Image.network(
                    card.image!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey),
                  )
                : const ColoredBox(color: Colors.grey),
          ),
          title: Text(
            card.headline,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${card.sourceName ?? card.category} · ${card.kind}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 12),
          onTap: () => _openCard(card),
        );
      },
    );
  }
}

class _CricketTriviaSheet extends StatefulWidget {
  const _CricketTriviaSheet();

  @override
  State<_CricketTriviaSheet> createState() => _CricketTriviaSheetState();
}

class _CricketTriviaSheetState extends State<_CricketTriviaSheet> {
  int? _selected;
  bool _revealed = false;

  static const _options = [
    'Dipendra Singh Airee (9 balls)',
    'Yuvraj Singh (12 balls)',
    'Chris Gayle (12 balls)',
    'AB de Villiers (16 balls)',
  ];
  static const _correctIndex = 0;

  void _choose(int idx) {
    if (_revealed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = idx;
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: CricitSpace.lg,
        left: CricitSpace.lg,
        right: CricitSpace.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + CricitSpace.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? CricitColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: CricitSpace.md),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CricitColors.scoreboard.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(CricitRadius.sm),
                ),
                child: const Icon(
                  Icons.sports_cricket,
                  color: CricitColors.scoreboard,
                  size: 20,
                ),
              ),
              const SizedBox(width: CricitSpace.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRICKET WORD WHEEL',
                      style: TextStyle(
                        fontFamily: CricitFonts.display,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Daily 1-Minute Cricket Trivia',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: CricitSpace.md),

          // Question Card
          Container(
            padding: const EdgeInsets.all(CricitSpace.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(CricitRadius.md),
              border: Border.all(color: CricitColors.outfield.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Who holds the official record for the fastest fifty in Men’s T20 International cricket history?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: CricitSpace.md),

          // Options
          for (var i = 0; i < _options.length; i++) ...[
            InkWell(
              onTap: () => _choose(i),
              borderRadius: BorderRadius.circular(CricitRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _revealed
                      ? (i == _correctIndex
                          ? Colors.green.withValues(alpha: 0.15)
                          : (_selected == i
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.transparent))
                      : (_selected == i
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(CricitRadius.md),
                  border: Border.all(
                    color: _revealed
                        ? (i == _correctIndex
                            ? Colors.green
                            : (_selected == i ? Colors.red : Colors.grey.withValues(alpha: 0.3)))
                        : Colors.grey.withValues(alpha: 0.3),
                    width: _revealed && (i == _correctIndex || _selected == i) ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _revealed && i == _correctIndex
                            ? Colors.green
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _options[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _revealed && i == _correctIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_revealed && i == _correctIndex)
                      const Icon(Icons.check_circle, color: Colors.green, size: 18)
                    else if (_revealed && _selected == i && i != _correctIndex)
                      const Icon(Icons.cancel, color: Colors.red, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CricitSpace.sm),
          ],

          // Explanation note once answered
          if (_revealed) ...[
            const SizedBox(height: CricitSpace.xs),
            Container(
              padding: const EdgeInsets.all(CricitSpace.sm),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(CricitRadius.sm),
              ),
              child: Text(
                _selected == _correctIndex
                    ? '🎯 Spot on! Dipendra Singh Airee reached 50 off 9 balls for Nepal against Mongolia in the 2023 Asian Games, breaking Yuvraj Singh’s 16-year record (12 balls vs England, 2007).'
                    : '💡 Trivia fact: Dipendra Singh Airee reached 50 off just 9 balls for Nepal in 2023, surpassing Yuvraj Singh’s iconic 12-ball benchmark from the 2007 T20 World Cup.',
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
