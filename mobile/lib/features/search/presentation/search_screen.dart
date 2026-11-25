import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/story_time.dart';
import '../../../core/widgets/arrive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/in_app_web_sheet.dart';
import '../../../core/widgets/youtube_poster.dart';
import '../../../l10n/l10n.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/domain/news_card.dart';
import '../../feed/presentation/feed_controller.dart';
import '../../feed/presentation/news_card_view.dart';

/// Search page (brief p.7): search bar, section shortcuts, top stories as a
/// notification-style list, and the Nxtspot grassroots spotlight.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentKey = 'recent_searches';
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  var _query = '';
  var _loading = false;
  List<NewsCard> _results = const [];
  List<String> _recent = const [];

  static const _chips = [
    'India',
    'Ranji Trophy',
    'Bumrah',
    'IPL 2026',
    'Syed Mushtaq Ali',
    'WPL',
    'Nxtspot',
    'Kohli',
  ];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() => _recent = p.getStringList(_recentKey) ?? const []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _remember(String q) async {
    if (q.length < 2) return;
    final next = [q, ..._recent.where((r) => r.toLowerCase() != q.toLowerCase())]
        .take(8)
        .toList();
    setState(() => _recent = next);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_recentKey, next);
  }

  Future<void> _clearRecent() async {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _recent = const []);
    final p = await SharedPreferences.getInstance();
    await p.remove(_recentKey);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  void _runChip(String text) {
    HapticFeedback.selectionClick();
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _search(text, remember: true);
  }

  Future<void> _search(String value, {bool remember = false}) async {
    setState(() {
      _query = value.trim();
      _loading = _query.isNotEmpty;
    });
    if (_query.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final q = _query;
    final lang = ref.read(settingsProvider).language;
    final found = await ref.read(feedRepositoryProvider).search(q, lang: lang);
    if (!mounted || q != _query) return;
    setState(() {
      _results = found;
      _loading = false;
    });
    if (remember) unawaited(_remember(q));
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
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, _, __) => Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            return Scaffold(
              appBar: AppBar(title: Text(_sectionLabel(context, card))),
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
        transitionsBuilder: (context, anim, _, child) {
          final t = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: t,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(t),
              child: child,
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
    final feed = ref.watch(feedControllerProvider('feed')).cards;
    final nxt = ref.watch(feedControllerProvider('nxtspot')).cards;
    final top = feed.where((c) => !c.isAd).take(5).toList();
    final nxtspot = nxt.where((c) => !c.isAd).take(6).toList();
    final focused = _focus.hasFocus;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CricitSpace.md,
              CricitSpace.md,
              CricitSpace.md,
              CricitSpace.sm,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CricitRadius.full),
                boxShadow: [
                  if (focused)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                onSubmitted: (v) => _search(v, remember: true),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: l10n.clearAll,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              child: _query.isNotEmpty
                  ? KeyedSubtree(
                      key: const ValueKey('results'),
                      child: _buildSearchResults(l10n, theme),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('discover'),
                      child: _buildDiscover(l10n, theme, top, nxtspot),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CricitSpace.md,
        CricitSpace.lg,
        CricitSpace.sm,
        CricitSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDiscover(
    L10n l10n,
    ThemeData theme,
    List<NewsCard> top,
    List<NewsCard> nxtspot,
  ) {
    var i = 0;
    return ListView(
      padding: const EdgeInsets.only(bottom: CricitSpace.xl),
      children: [
        Arrive(
          index: i++,
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CricitSpace.md),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: CricitSpace.sm),
              itemBuilder: (context, n) => ActionChip(
                label: Text(_chips[n]),
                onPressed: () => _runChip(_chips[n]),
              ),
            ),
          ),
        ),
        if (_recent.isNotEmpty)
          Arrive(
            index: i++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader(
                  theme,
                  l10n.recentSearches,
                  trailing: TextButton(
                    onPressed: _clearRecent,
                    child: Text(l10n.clearAll),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CricitSpace.md,
                  ),
                  child: Wrap(
                    spacing: CricitSpace.sm,
                    runSpacing: CricitSpace.xs,
                    children: [
                      for (final r in _recent)
                        InputChip(
                          avatar: const Icon(Icons.history_rounded, size: 16),
                          label: Text(r),
                          onPressed: () => _runChip(r),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Arrive(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CricitSpace.md,
              CricitSpace.lg,
              CricitSpace.md,
              0,
            ),
            child: _QuizBanner(onTap: () => _showTriviaDialog(context)),
          ),
        ),
        if (top.isNotEmpty) ...[
          Arrive(
            index: i++,
            child: _sectionHeader(theme, l10n.topStories),
          ),
          for (final card in top)
            Arrive(
              index: i++,
              child: _StoryTile(card: card, onTap: () => _openCard(card)),
            ),
        ],
        if (nxtspot.isNotEmpty) ...[
          Arrive(
            index: i++,
            child: _sectionHeader(theme, l10n.nxtspotSpotlight),
          ),
          Arrive(
            index: i++,
            child: SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CricitSpace.md,
                ),
                itemCount: nxtspot.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: CricitSpace.md - 4),
                itemBuilder: (context, n) => _SpotlightCard(
                  card: nxtspot[n],
                  onTap: () => _openCard(nxtspot[n]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(L10n l10n, ThemeData theme) {
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
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: CricitSpace.lg),
      itemCount: _results.length + 1,
      itemBuilder: (context, n) {
        if (n == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              CricitSpace.md,
              CricitSpace.sm,
              CricitSpace.md,
              CricitSpace.xs,
            ),
            child: Text(
              l10n.resultsFor(_results.length, _query),
              style: theme.textTheme.labelMedium,
            ),
          );
        }
        final card = _results[n - 1];
        return Arrive(
          index: n,
          child: _StoryTile(
            card: card,
            onTap: () {
              unawaited(_remember(_query));
              _openCard(card);
            },
          ),
        );
      },
    );
  }
}

String _sectionLabel(BuildContext context, NewsCard card) {
  final l10n = L10n.of(context);
  if (card.kind == 'nxtspot' || card.category == 'grassroots') {
    return l10n.tabNxtspot;
  }
  if (card.isVideo) return l10n.tabVideo;
  return switch (card.category) {
    'domestic' => l10n.tabDomestic,
    'international' => l10n.tabInternational,
    _ => l10n.appName,
  };
}

String? _thumbOf(NewsCard card) =>
    card.image ?? (card.videoId == null ? null : youTubePosterUrl(card.videoId!));

/// Notification-style row: headline and credit on the left, thumbnail right.
class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.card, required this.onTap});

  final NewsCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = _thumbOf(card);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CricitSpace.md,
          vertical: CricitSpace.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: CricitSpace.xs),
                  Row(
                    children: [
                      if (card.isBreaking) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: CricitSpace.xs + 2),
                      ],
                      Flexible(
                        child: Text(
                          '${card.sourceName ?? _sectionLabel(context, card)} · ${storyTimeLabel(card.publishedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: CricitSpace.md - 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(CricitRadius.md - 4),
              child: SizedBox(
                width: 84,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb == null)
                      ColoredBox(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.sports_cricket,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => ColoredBox(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    if (card.isVideo)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 26,
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

/// Tall card in the Nxtspot spotlight carousel. Presses down slightly.
class _SpotlightCard extends StatefulWidget {
  const _SpotlightCard({required this.card, required this.onTap});

  final NewsCard card;
  final VoidCallback onTap;

  @override
  State<_SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<_SpotlightCard> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = _thumbOf(widget.card);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _down ? 0.97 : 1,
        child: SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(CricitRadius.md),
                child: SizedBox(
                  height: 120,
                  width: 168,
                  child: thumb == null
                      ? const ColoredBox(color: CricitColors.outfield)
                      : CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: CricitColors.outfield),
                        ),
                ),
              ),
              const SizedBox(height: CricitSpace.sm),
              Text(
                widget.card.headline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry to the daily one-question quiz.
class _QuizBanner extends StatelessWidget {
  const _QuizBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: CricitColors.outfield,
      borderRadius: BorderRadius.circular(CricitRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CricitRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(CricitSpace.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CricitColors.scoreboard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_cricket,
                  color: CricitColors.ink,
                ),
              ),
              const SizedBox(width: CricitSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily cricket quiz',
                      style: TextStyle(
                        fontFamily: CricitFonts.display,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CricitColors.onOutfield,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'One question, one minute. Keep your streak going.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: CricitColors.onOutfield.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CricitColors.onOutfield,
              ),
            ],
          ),
        ),
      ),
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
