import 'package:cricit/app/app.dart';
import 'package:cricit/features/feed/data/feed_repository.dart';
import 'package:cricit/features/feed/data/fixture_feed.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/news_card_view.dart';
import 'package:dio/dio.dart';
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
      find.textContaining('Virat Kohli’s masterclass nets session'),
      findsOneWidget,
    );
  });
}
