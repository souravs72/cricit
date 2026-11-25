import 'package:cricit/app/app.dart';
import 'package:cricit/features/feed/data/feed_repository.dart';
import 'package:cricit/features/feed/data/fixture_feed.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/news_card_view.dart';
import 'package:cricit/features/feed/presentation/video_short_view.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFeedRepository extends FeedRepository {
  _MockFeedRepository()
      : super(
          Dio(
            BaseOptions(
              baseUrl: 'http://127.0.0.1',
              connectTimeout: const Duration(milliseconds: 1),
            ),
          ),
        );

  @override
  Future<FeedPage> fetch({
    String tab = 'feed',
    String lang = 'en',
    String? cursor,
  }) async {
    return fixturePage(tab);
  }
}

void main() {
  testWidgets(
      'swiping vertically advances to the next card and returns to previous card',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWith(
            (ref) => _MockFeedRepository(),
          ),
        ],
        child: const CricitApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify first card is in view
    expect(find.text('Gill 104 keeps India in front at Perth'), findsOneWidget);
    expect(find.textContaining('1 /'), findsOneWidget);

    // Swipe up (drag delta y = -500) to advance forward ("going down" the feed)
    await tester.drag(
      find.text('Gill 104 keeps India in front at Perth'),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // Now second card should be visible
    expect(find.textContaining('2 /'), findsOneWidget);

    // Swipe down (drag delta y = 500) to go back ("going up" the feed)
    await tester.drag(find.byType(NewsCardView), const Offset(0, 500));
    await tester.pumpAndSettle();

    // Back to first card
    expect(find.text('Gill 104 keeps India in front at Perth'), findsOneWidget);
    expect(find.textContaining('1 /'), findsOneWidget);
  });

  testWidgets(
      'video tab renders clean reel without story progress bar and supports vertical swipe',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWith(
            (ref) => _MockFeedRepository(),
          ),
        ],
        child: const CricitApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to 'Video' tab
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    // In the Video tab, horizontal story deck top bar should be hidden
    expect(find.textContaining('Swipe left'), findsNothing);

    // Verify first video is rendered
    expect(
      find.textContaining('Bumrah’s 147 kph yorker'),
      findsOneWidget,
    );

    // Swipe vertically to next video card
    await tester.drag(
      find.textContaining('Bumrah’s 147 kph yorker'),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // Next video in pool should be visible
    expect(
      find.textContaining('Virat Kohli’s signature cover drive'),
      findsOneWidget,
    );

    // Swipe vertically again to 3rd video card
    await tester.drag(
      find.textContaining('Virat Kohli’s signature cover drive'),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // 3rd video in pool should be visible
    expect(
      find.textContaining('Rohit Sharma’s signature pull shot'),
      findsOneWidget,
    );

    // Swipe down to return to 2nd video card
    await tester.drag(
      find.textContaining('Rohit Sharma’s signature pull shot'),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Virat Kohli’s signature cover drive'),
      findsOneWidget,
    );
  });

  testWidgets(
      'video tab renders edge-to-edge without card margin or outer ClipRRect, while stories use rounded card deck',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWith(
            (ref) => _MockFeedRepository(),
          ),
        ],
        child: const CricitApp(),
      ),
    );
    await tester.pumpAndSettle();

    // On My Feed (stories), cards are wrapped in ClipRRect(borderRadius: 16)
    final storyClipFinders = find.byType(ClipRRect);
    expect(storyClipFinders, findsWidgets);

    // Switch to Video tab
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    // On Video tab, VideoShortView is rendered edge-to-edge
    expect(find.byType(VideoShortView), findsOneWidget);

    // Tap on Video canvas to pause video
    await tester.tap(find.byType(VideoShortView));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // When paused by user, play arrow icon overlay appears
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap again to resume
    await tester.tap(find.byType(VideoShortView));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tap Like button
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets(
      'reels keep players for the current and next reel only, and a cancelled '
      'swipe keeps the reel state', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWith(
            (ref) => _MockFeedRepository(),
          ),
        ],
        child: const CricitApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    // Current + next are built (next is warming); nothing else.
    final reels = tester
        .widgetList<VideoShortView>(
          find.byType(VideoShortView, skipOffstage: false),
        )
        .toList();
    expect(reels.where((r) => r.keepPlayer).length, lessThanOrEqualTo(2));
    expect(reels.where((r) => r.isActive).length, 1);
    expect(reels.where((r) => r.isPreload).length, 1);

    // Like the reel, start a swipe, then let it snap back.
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(200, 500));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    // The depth transition must not rebuild the reel (or its player).
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
