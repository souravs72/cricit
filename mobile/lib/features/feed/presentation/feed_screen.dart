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
import 'ad_views.dart';
import 'news_card_view.dart';
import 'video_short_view.dart';

const _tabs = ['feed', 'video', 'domestic', 'international', 'nxtspot'];

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, this.openCardId});

  final String? openCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final labels = [
      l10n.tabFeed,
      l10n.tabVideo,
      l10n.tabDomestic,
      l10n.tabInternational,
      l10n.tabNxtspot,
    ];
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: 0,
      child: Column(
        children: [
          Material(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CricitSpace.sm,
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: CricitSpace.md - 2,
                  ),
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(CricitRadius.full),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 9),
                  // A pill that slides between sections as you switch.
                  indicator: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                  ),
                  labelColor: primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontFamily: CricitFonts.body,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: CricitFonts.body,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                  tabs: [for (final l in labels) Tab(text: l)],
                  onTap: (_) => HapticFeedback.selectionClick(),
                ),
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

                      // Tactile card deck: the page being left sinks back a
                      // little under the one arriving; the picture drifts
                      // against the swipe and the text settles in.
                      return AnimatedBuilder(
                        animation: _page,
                        builder: (context, child) {
                          final d = _pageDelta(i);
                          final Widget page = card.isAd
                              ? AdPageView(
                                  key: ValueKey('ad-${card.id}'),
                                  slot: card.ad!,
                                )
                              : NewsCardView(
                                  key: ValueKey('story-${card.id}'),
                                  card: card,
                                  saved: settings.bookmarks.contains(card.id),
                                  forceHindi: hindi,
                                  indexLabel:
                                      'Story ${i + 1} of ${snap.cards.length}',
                                  onOpenSource: card.url == null
                                      ? null
                                      : () => _open(card),
                                  onToggleSave: () => ref
                                      .read(settingsProvider.notifier)
                                      .toggleBookmark(card.id),
                                  onToggleLanguage: card.hasHindi
                                      ? () => setState(
                                            () => _hindiOverride[card.id] =
                                                !hindi,
                                          )
                                      : null,
                                  parallax: d,
                                  settle: 1 - d.abs(),
                                );
                          final shadowAlpha =
                              (0.18 * (1 - d.abs())).clamp(0.0, 0.18);
                          final leaving = d > 0 && !reduceMotion;
                          return Transform.scale(
                            scale: leaving ? 1 - 0.05 * d : 1,
                            child: Container(
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
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    page,
                                    IgnorePointer(
                                      child: ColoredBox(
                                        color: Colors.black.withValues(
                                          alpha: leaving ? 0.35 * d : 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
        // "New posts" slides down from the tab bar when fresh cards arrive.
        Positioned(
          top: CricitSpace.lg,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !snap.hasNewPosts,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              offset: snap.hasNewPosts ? Offset.zero : const Offset(0, -1.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: snap.hasNewPosts ? 1 : 0,
                child: Center(
                  child: Material(
                    color: CricitColors.scoreboard,
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ctrl.revealNewPosts();
                        if (_page.hasClients) _page.jumpToPage(0);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CricitSpace.md,
                          vertical: CricitSpace.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: CricitColors.ink,
                            ),
                            const SizedBox(width: CricitSpace.xs),
                            Text(
                              l10n.newPosts,
                              style: const TextStyle(
                                fontFamily: CricitFonts.body,
                                fontWeight: FontWeight.w600,
                                color: CricitColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Story progress across the top of the deck: one segment per story (up to
/// 18), the current one in scoreboard amber, and a compact counter. Arrow
/// buttons step the deck for mouse and keyboard users.
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

    final displaySegments = total.clamp(1, 18);
    final activeSegment =
        ((currentIndex / (total - 1).clamp(1, 9999)) * (displaySegments - 1))
            .round();
    const shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CricitSpace.md,
        CricitSpace.sm,
        CricitSpace.md,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(displaySegments, (index) {
              final isCurrent = index == activeSegment;
              final isFilled = index < activeSegment;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: isCurrent ? 3.5 : 2.5,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? CricitColors.scoreboard
                        : Colors.white.withValues(alpha: isFilled ? 0.9 : 0.4),
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _DeckArrow(
                icon: Icons.keyboard_arrow_up_rounded,
                label: 'Previous story',
                onTap: onPrevious,
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  '${currentIndex + 1} / $total',
                  key: ValueKey(currentIndex),
                  style: const TextStyle(
                    fontFamily: CricitFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: shadow,
                  ),
                ),
              ),
              const Spacer(),
              _DeckArrow(
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Next story',
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckArrow extends StatelessWidget {
  const _DeckArrow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onTap == null ? 0 : 1,
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
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
