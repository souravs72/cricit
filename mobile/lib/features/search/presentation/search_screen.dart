import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../trivia/data/trivia_repository.dart';
import '../../trivia/domain/trivia.dart';

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
    final next = [
      q,
      ..._recent.where((r) => r.toLowerCase() != q.toLowerCase()),
    ].take(8).toList();
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
              separatorBuilder: (_, __) =>
                  const SizedBox(width: CricitSpace.sm),
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
    card.image ??
    (card.videoId == null ? null : youTubePosterUrl(card.videoId!));

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

/// Entry to the daily 6-ball over trivia.
class _QuizBanner extends StatelessWidget {
  const _QuizBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF0D2318) : CricitColors.outfield,
      borderRadius: BorderRadius.circular(CricitRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CricitRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(CricitSpace.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏏', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: CricitSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'The Daily Over',
                          style: TextStyle(
                            fontFamily: CricitFonts.display,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CricitColors.onOutfield,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CricitColors.onOutfield.withValues(alpha: 0.18),
                            borderRadius:
                                BorderRadius.circular(CricitRadius.sm),
                          ),
                          child: const Text(
                            'Daily cricket quiz',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: CricitColors.onOutfield,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '6 balls · 6 questions · Keep your streak alive',
                      style: TextStyle(
                        fontSize: 12,
                        color: CricitColors.onOutfield.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CricitColors.onOutfield.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CricitRadius.full),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CricitColors.onOutfield,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CricketTriviaSheet extends ConsumerStatefulWidget {
  const _CricketTriviaSheet();

  @override
  ConsumerState<_CricketTriviaSheet> createState() =>
      _CricketTriviaSheetState();
}

class _CricketTriviaSheetState extends ConsumerState<_CricketTriviaSheet> {
  DailyOver? _over;
  bool _loading = true;
  bool _checking = false;
  TriviaProblem? _problem;
  int _currentBall = 0; // 0..5
  int? _selected;
  bool _revealed = false;
  int? _currentCorrectIndex;
  String? _currentExplanation;
  final List<int?> _userAnswers = List.filled(6, null);
  final List<bool?> _ballResults = List.filled(6, null);
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _loadTrivia();
  }

  Future<void> _loadTrivia() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    if (!ref.read(settingsProvider).signedIn) {
      _show(problem: TriviaProblem.signInRequired);
      return;
    }
    final repo = ref.read(triviaRepositoryProvider);
    final over = await repo.fetchDailyOver();
    if (over.problem != null) {
      _show(problem: over.problem);
      return;
    }
    final progress = await repo.fetchProgress();
    if (progress.problem != null) {
      _show(problem: progress.problem);
      return;
    }
    _show(over: over.value, answered: progress.value!);
  }

  /// Applies a load result, resuming from balls already answered on the server today.
  void _show({
    DailyOver? over,
    List<AnsweredBall> answered = const [],
    TriviaProblem? problem,
  }) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _problem = problem;
      _over = over;
      for (final a in answered) {
        final i = a.ballNumber - 1;
        _userAnswers[i] = a.userAnswer;
        _ballResults[i] = a.isCorrect;
      }
      final next = _userAnswers.indexWhere((a) => a == null);
      _completed = over != null && next == -1;
      _currentBall = next == -1 ? 5 : next;
    });
  }

  Future<void> _choose(int idx) async {
    if (_revealed ||
        _checking ||
        _over == null ||
        _currentBall >= _over!.balls.length) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _checking = true;
      _selected = idx;
    });
    final result = await ref.read(triviaRepositoryProvider).verifyBall(
          ballNumber: _currentBall + 1,
          answer: idx,
        );
    if (!mounted) return;
    final verification = result.value;
    if (verification == null) {
      setState(() {
        _checking = false;
        _selected = null;
      });
      _reportProblem(result.problem!);
      return;
    }
    setState(() {
      _checking = false;
      _selected = verification.userAnswer;
      _revealed = true;
      _currentCorrectIndex = verification.correctIndex;
      _currentExplanation = verification.explanation;
      _userAnswers[_currentBall] = verification.userAnswer;
      _ballResults[_currentBall] = verification.isCorrect;
    });
  }

  void _reportProblem(TriviaProblem problem) {
    if (problem == TriviaProblem.offline) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text("Couldn't check that answer. Tap it again."),
        ),
      );
      return;
    }
    setState(() => _problem = problem);
  }

  void _nextBall() {
    unawaited(HapticFeedback.lightImpact());
    if (_currentBall < 5) {
      setState(() {
        _currentBall++;
        _selected = null;
        _revealed = false;
        _currentCorrectIndex = null;
        _currentExplanation = null;
      });
    } else {
      _finishOver();
    }
  }

  Future<void> _finishOver() async {
    unawaited(HapticFeedback.mediumImpact());
    // Points were banked by the server when ball 6 was verified; this only syncs totals.
    await ref.read(triviaRepositoryProvider).finishOver();
    if (mounted) {
      setState(() {
        _completed = true;
      });
    }
  }

  Widget _buildProblem(BuildContext context, TriviaProblem problem) {
    final (icon, title, body, action, onAction) = switch (problem) {
      TriviaProblem.signInRequired => (
          Icons.lock_outline_rounded,
          'Sign in to play',
          'Every Daily Over earns Cricket IQ points, so it is for signed-in players.',
          'Sign in with phone',
          () {
            Navigator.of(context).pop();
            context.push('/signin');
          },
        ),
      TriviaProblem.nameRequired => (
          Icons.badge_outlined,
          'Add your name to play',
          'Set a display name on your profile so your points can be banked.',
          'Go to profile',
          () {
            Navigator.of(context).pop();
            context.go('/profile');
          },
        ),
      TriviaProblem.notReady => (
          Icons.hourglass_top_rounded,
          "Today's over is being prepared",
          'Fresh questions are on their way. Check back in a little while.',
          'Try again',
          _loadTrivia,
        ),
      TriviaProblem.offline => (
          Icons.wifi_off_rounded,
          "Couldn't load today's over",
          'Check your connection and try again.',
          'Try again',
          _loadTrivia,
        ),
    };
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CricitSpace.lg),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: CricitSpace.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: CricitSpace.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(onPressed: onAction, child: Text(action)),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'trending':
        return '🔥 TRENDING CRICKET';
      case 'domestic':
        return '🏆 INDIAN DOMESTIC (RANJI / SMAT / VHT)';
      case 'grassroots':
        return '🌱 INDIAN GRASSROOTS (NXTSPOT / HARRIS)';
      case 'ipl':
        return '⚡ IPL & T20 LEAGUE';
      case 'international':
        return '🌍 INTERNATIONAL CRICKET';
      case 'rules':
        return '📜 LAWS OF CRICKET';
      default:
        return '🏏 CRICKET TRIVIA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final score = _ballResults.where((r) => r == true).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        top: CricitSpace.md,
        left: CricitSpace.lg,
        right: CricitSpace.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + CricitSpace.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? CricitColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: CricitSpace.sm),

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE DAILY OVER',
                        style: TextStyle(
                          fontFamily: CricitFonts.display,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _completed
                            ? 'Scorecard · Final Over Result'
                            : '6 Balls · 1 Point Per Ball · Today\'s Over',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
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
            const SizedBox(height: CricitSpace.sm),

            // Ball indicators (1 to 6)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF141F18) : const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(CricitRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(6, (i) {
                  final isCurrent = i == _currentBall && !_completed;
                  final res = _ballResults[i];
                  Color bg;
                  Color border;
                  Widget child;

                  if (res == true) {
                    bg = Colors.green.withValues(alpha: 0.2);
                    border = Colors.green;
                    child =
                        const Icon(Icons.check, size: 14, color: Colors.green);
                  } else if (res == false) {
                    bg = Colors.red.withValues(alpha: 0.2);
                    border = Colors.red;
                    child =
                        const Icon(Icons.close, size: 14, color: Colors.red);
                  } else if (isCurrent) {
                    bg = theme.colorScheme.primary.withValues(alpha: 0.15);
                    border = theme.colorScheme.primary;
                    child = Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  } else {
                    bg = Colors.transparent;
                    border = Colors.grey.withValues(alpha: 0.4);
                    child = Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }

                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: border,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: child,
                  );
                }),
              ),
            ),
            const SizedBox(height: CricitSpace.md),

            // Content body: Loading, Question or Scorecard
            if (_loading)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (_problem != null)
              _buildProblem(context, _problem!)
            else if (_completed)
              _buildScorecard(context, theme, isDark, settings, score)
            else
              _buildQuestionView(context, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    if (_over == null || _currentBall >= _over!.balls.length) {
      return const SizedBox.shrink();
    }
    final q = _over!.balls[_currentBall];
    final correctIdx = _currentCorrectIndex ?? q.correctIndex ?? 0;
    final explanation = _currentExplanation ?? q.explanation ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Pill
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CricitColors.outfield.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CricitRadius.full),
            ),
            child: Text(
              _categoryLabel(q.category),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: CricitColors.outfield,
              ),
            ),
          ),
        ),
        const SizedBox(height: CricitSpace.xs),

        // Question Card
        Container(
          padding: const EdgeInsets.all(CricitSpace.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(CricitRadius.md),
            border: Border.all(
              color: CricitColors.outfield.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            q.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: CricitSpace.md),

        // Options
        for (var i = 0; i < q.options.length; i++) ...[
          InkWell(
            onTap: () => _choose(i),
            borderRadius: BorderRadius.circular(CricitRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _revealed
                    ? (i == correctIdx
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
                      ? (i == correctIdx
                          ? Colors.green
                          : (_selected == i
                              ? Colors.red
                              : Colors.grey.withValues(alpha: 0.3)))
                      : Colors.grey.withValues(alpha: 0.3),
                  width: _revealed && (i == correctIdx || _selected == i)
                      ? 1.5
                      : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    String.fromCharCode(65 + i),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _revealed && i == correctIdx ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.options[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _revealed && i == correctIdx
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_revealed && i == correctIdx)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    )
                  else if (_revealed && _selected == i && i != correctIdx)
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
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(CricitRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected == correctIdx ? '🎯 ' : '💡 ',
                  style: const TextStyle(fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    explanation,
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CricitSpace.md),

          // Next Ball CTA
          FilledButton.icon(
            onPressed: _nextBall,
            style: FilledButton.styleFrom(
              backgroundColor: CricitColors.outfield,
              foregroundColor: CricitColors.onOutfield,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CricitRadius.md),
              ),
            ),
            icon: Icon(
              _currentBall < 5
                  ? Icons.arrow_forward_rounded
                  : Icons.scoreboard_outlined,
              size: 18,
            ),
            label: Text(
              _currentBall < 5
                  ? 'Bowl Next Ball (${_currentBall + 2}/6)'
                  : 'Finish Over & See Scorecard',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScorecard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppSettings settings,
    int score,
  ) {
    final title = score == 6
        ? 'Maiden Over! Perfect 6/6 Runs 🌟'
        : score >= 4
            ? 'Superb Striking! $score/6 Runs 🏏'
            : score >= 2
                ? 'Steady Knock! $score/6 Runs 🎯'
                : 'Tough Spell! $score/6 Runs 💪';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trophy & Score Badge
        Container(
          padding: const EdgeInsets.all(CricitSpace.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1B2E24), const Color(0xFF0F1E16)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CricitColors.outfield.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CricitColors.outfield.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: CricitSpace.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: CricitFonts.display,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You bowled all 6 balls of today\'s daily over.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CricitSpace.md),

        // Auth Gating Banner
        if (settings.signedIn) ...[
          Container(
            padding: const EdgeInsets.all(CricitSpace.md),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CricitRadius.md),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: CricitSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+$score Cricket IQ Points Banked!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Total: ${settings.triviaPoints} pts · Streak: ${settings.triviaStreak} days',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(CricitSpace.md),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CricitRadius.md),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score: $score/6 — Sign In to Bank Points!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Points only count towards your profile rank and streak when signed in with phone.',
                  style: TextStyle(fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: CricitSpace.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/signin');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: CricitColors.outfield,
                      foregroundColor: CricitColors.onOutfield,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.phone_android_rounded, size: 16),
                    label: const Text(
                      'Sign In to Save Points',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: CricitSpace.md),

        // Done button
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
