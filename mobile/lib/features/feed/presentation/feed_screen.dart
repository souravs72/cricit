import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/in_app_web_sheet.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/youtube_poster.dart';
import '../../../l10n/l10n.dart';
import '../domain/news_card.dart';
import 'feed_controller.dart';
import 'news_card_view.dart';
import 'video_short_view.dart';

const _tabs = ['feed', 'video', 'domestic', 'international', 'nxtspot'];

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.openCardId});

  final String? openCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            elevation: isDark ? 0 : 1,
            shadowColor: Colors.black12,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: CricitColors.outfield,
                indicatorWeight: 3,
                labelColor:
                    isDark ? CricitColors.outfieldDark : CricitColors.outfield,
                unselectedLabelColor:
                    isDark ? CricitColors.inkMutedDark : CricitColors.inkMuted,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: [for (final l in labels) Tab(text: l)],
                onTap: (_) => HapticFeedback.selectionClick(),
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
  var _currentIndex = 0;
  var _lastWheelTimestamp = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _preloadUpcoming(List<NewsCard> cards, int current) {
    if (!mounted) return;
    // Reels look 3 ahead so a fast flicker still lands on a painted poster.
    final ahead = widget.tab == 'video' ? 3 : 2;
    for (int offset = 1; offset <= ahead; offset++) {
      final nextIdx = current + offset;
      if (nextIdx >= cards.length) break;
      final next = cards[nextIdx];
      final url = next.image ??
          (next.videoId != null ? youTubePosterUrl(next.videoId!) : null);
      if (url == null) continue;
      precacheImage(CachedNetworkImageProvider(url), context)
          .catchError((Object _) {});
    }
  }

  /// Signed distance of page [i] from the viewport, clamped to -1..1.
  /// Positive while [i] is leaving upward (or sitting above), negative while
  /// it is arriving from below.
  double _pageDelta(int i) {
    double d;
    if (_page.hasClients && _page.position.haveDimensions) {
      d = (_page.page ?? _page.initialPage.toDouble()) - i;
    } else {
      d = (_currentIndex - i).toDouble();
    }
    return d.clamp(-1.0, 1.0);
  }

  void _goToNext(int total) {
    if (_currentIndex < total - 1 && _page.hasClients) {
      HapticFeedback.lightImpact();
      _page.nextPage(
        duration: Duration(milliseconds: widget.tab == 'video' ? 420 : 320),
        curve:
            widget.tab == 'video' ? Curves.easeInOutCubic : Curves.easeOutCubic,
      );
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0 && _page.hasClients) {
      HapticFeedback.lightImpact();
      _page.previousPage(
        duration: Duration(milliseconds: widget.tab == 'video' ? 420 : 320),
        curve:
            widget.tab == 'video' ? Curves.easeInOutCubic : Curves.easeOutCubic,
      );
    }
  }

  void _handlePointerSignal(PointerSignalEvent event, int total) {
    if (event is PointerScrollEvent) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastWheelTimestamp < 260) return;
      if (event.scrollDelta.dy > 12) {
        _lastWheelTimestamp = now;
        _goToNext(total);
      } else if (event.scrollDelta.dy < -12) {
        _lastWheelTimestamp = now;
        _goToPrevious();
      }
    }
  }

  Future<void> _open(NewsCard card) async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    if (card.url == null) return;
    // Embed news reading in-app via modal sheet so the user remains in CRICIT
    await InAppWebSheet.show(
      context,
      url: card.url!,
      sourceName: card.sourceName ?? 'CRICIT',
      headline: card.headlineFor(hindi: _hindiOverride[card.id] ?? false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final snap = ref.watch(feedControllerProvider(widget.tab));
    final ctrl = ref.read(feedControllerProvider(widget.tab).notifier);
    final settings = ref.watch(settingsProvider);
    final isVideoTab = widget.tab == 'video';
    final reduceMotion = MediaQuery.of(context).disableAnimations;

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
        _preloadUpcoming(snap.cards, 0);
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
        body = Listener(
          onPointerSignal: (event) =>
              _handlePointerSignal(event, snap.cards.length),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final vx = details.primaryVelocity ?? 0;
              if (vx < -150) {
                _goToNext(snap.cards.length);
              } else if (vx > 150) {
                if (_currentIndex > 0) _goToPrevious();
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is OverscrollNotification &&
                    notification.overscroll < -24 &&
                    _currentIndex == 0) {
                  HapticFeedback.mediumImpact();
                  ctrl.refresh();
                }
                return false;
              },
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _page,
                    scrollDirection: Axis.vertical,
                    // Reels keep the neighbouring page built, so the next
                    // reel's player exists (and is buffering) before the
                    // swipe starts instead of being created mid-swipe.
                    allowImplicitScrolling: isVideoTab,
                    physics: isVideoTab
                        ? const _ReelScrollPhysics()
                        : const PageScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                    itemCount: snap.cards.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                      HapticFeedback.selectionClick();
                      ctrl.onPageChanged(idx);
                      _preloadUpcoming(snap.cards, idx);
                    },
                    itemBuilder: (context, i) {
                      final card = snap.cards[i];
                      final hindi = _hindiOverride[card.id] ?? settings.isHindi;
                      final isCurrent = i == _currentIndex;
                      final isReel =
                          isVideoTab || (card.isVideo && card.summary.isEmpty);

                      if (isReel) {
                        return AnimatedBuilder(
                          animation: _page,
                          builder: (context, _) {
                            final d = _pageDelta(i);
                            final reel = VideoShortView(
                              key: ValueKey('short-${card.id}-${card.videoId}'),
                              card: card,
                              saved: settings.bookmarks.contains(card.id),
                              onToggleSave: () => ref
                                  .read(settingsProvider.notifier)
                                  .toggleBookmark(card.id),
                              indexLabel:
                                  'Video Short ${i + 1} of ${snap.cards.length}',
                              onSwipeNext: i < snap.cards.length - 1
                                  ? () => _goToNext(snap.cards.length)
                                  : null,
                              onSwipePrevious: i > 0 ? _goToPrevious : null,
                              isActive: isCurrent,
                              isPreload: i == _currentIndex + 1,
                              // At most two live players: this one and the next.
                              keepPlayer:
                                  i == _currentIndex || i == _currentIndex + 1,
                              chromeVisibility:
                                  reduceMotion ? 1 : (1 - d.abs()).clamp(0, 1),
                            );
                            return _ReelDepthTransition(
                              delta: reduceMotion ? 0 : d,
                              child: reel,
                            );
                          },
                        );
                      }

                      final cardWidget = NewsCardView(
                        key: ValueKey('story-${card.id}'),
                        card: card,
                        saved: settings.bookmarks.contains(card.id),
                        forceHindi: hindi,
                        indexLabel: 'Story ${i + 1} of ${snap.cards.length}',
                        onOpenSource:
                            card.url == null ? null : () => _open(card),
                        onToggleSave: () => ref
                            .read(settingsProvider.notifier)
                            .toggleBookmark(card.id),
                        onToggleLanguage: card.hasHindi
                            ? () =>
                                setState(() => _hindiOverride[card.id] = !hindi)
                            : null,
                      );

                      // Tactile card deck: the page being left sinks back a
                      // little under the one arriving.
                      return AnimatedBuilder(
                        animation: _page,
                        builder: (context, child) {
                          final clamped = _pageDelta(i);
                          final shadowAlpha =
                              (1.0 - clamped.abs()).clamp(0.2, 0.65);
                          final shadowOffsetY = clamped < 0 ? -8.0 : 8.0;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: shadowAlpha),
                                  blurRadius: 22,
                                  spreadRadius: 3,
                                  offset: Offset(0, shadowOffsetY),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            ),
                          );
                        },
                        child: cardWidget,
                      );
                    },
                  ),

                  // Segmented story timeline & deck navigation bar at top (stories only, not video reels)
                  if (widget.tab != 'video')
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _DeckTopBar(
                        currentIndex: _currentIndex,
                        total: snap.cards.length,
                        onPrevious: _currentIndex > 0 ? _goToPrevious : null,
                        onNext: _currentIndex < snap.cards.length - 1
                            ? () => _goToNext(snap.cards.length)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: CricitColors.scoreboard,
                  foregroundColor: CricitColors.ink,
                  elevation: 4,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ctrl.revealNewPosts();
                  if (_page.hasClients) _page.jumpToPage(0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward, size: 14),
                    const SizedBox(width: 4),
                    Text(l10n.newPosts),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeckTopBar extends StatelessWidget {
  const _DeckTopBar({
    required this.currentIndex,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  final int currentIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();

    // Max 18 segment dashes for clear readability across screen widths
    final displaySegments = total.clamp(1, 18);
    final activeSegment =
        ((currentIndex / (total - 1).clamp(1, 9999)) * (displaySegments - 1))
            .round();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        CricitSpace.md,
        CricitSpace.xs,
        CricitSpace.md,
        4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segmented Progress Bar
          Row(
            children: List.generate(displaySegments, (index) {
              final isFilled = index <= activeSegment;
              final isCurrent = index == activeSegment;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? CricitColors.scoreboard
                        : (isFilled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Subtle Deck Info Row with Swipe Cue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous story arrow button
              GestureDetector(
                onTap: onPrevious,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: onPrevious != null
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 16,
                        color: onPrevious != null
                            ? Colors.white
                            : Colors.transparent,
                      ),
                      if (onPrevious != null)
                        const Text(
                          ' Prev',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Deck Counter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(CricitRadius.full),
                ),
                child: Text(
                  '${currentIndex + 1} / $total',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Next story button / swipe cue
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: onNext != null
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onNext != null)
                        Text(
                          currentIndex == 0 ? 'Swipe left ' : 'Next ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color:
                            onNext != null ? Colors.white : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reel paging that settles quicker than the default and treats a short,
/// deliberate flick as a page turn, like the major short-video apps.
class _ReelScrollPhysics extends PageScrollPhysics {
  const _ReelScrollPhysics({super.parent});

  @override
  _ReelScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _ReelScrollPhysics(parent: buildParent(ancestor));

  @override
  ScrollPhysics? buildParent(ScrollPhysics? ancestor) =>
      const ClampingScrollPhysics().applyTo(ancestor);

  @override
  double get minFlingVelocity => 60;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.4,
        stiffness: 140,
        ratio: 1,
      );
}

/// Depth swipe between reels: the reel being left recedes (drifts slower
/// than the finger, shrinks slightly, rounds its corners and dims) while the
/// next one slides over it at full speed. Pages later in the list paint on
/// top, so the arriving reel always covers the departing one.
class _ReelDepthTransition extends StatelessWidget {
  const _ReelDepthTransition({required this.delta, required this.child});

  /// Page offset from `_pageDelta`: >0 while leaving upward.
  final double delta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Always the same widget structure (identity values at rest): changing
    // the tree shape would rebuild the reel's State and its video player.
    final t = delta.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Transform.translate(
          // Undo 55% of the page's upward travel, so it lags behind.
          offset: Offset(0, t * h * 0.55),
          child: Transform.scale(
            scale: 1 - 0.08 * t,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CricitRadius.md * 2 * t),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.6 * t),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
