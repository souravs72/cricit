import 'package:cricit/app/app.dart';
import 'package:cricit/features/feed/data/feed_repository.dart';
import 'package:cricit/features/feed/data/fixture_feed.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixtureRepo extends FeedRepository {
  _FixtureRepo()
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
  }) async =>
      fixturePage(tab);

  @override
  Future<List<NewsCard>> search(String query, {String lang = 'en'}) async =>
      fixtureCards()
          .where((c) => c.headline.toLowerCase().contains(query.toLowerCase()))
          .toList();
}

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [feedRepositoryProvider.overrideWith((ref) => _FixtureRepo())],
      child: const CricitApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search shows top stories and a chip runs a search',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    expect(find.text('Top stories'), findsOneWidget);
    expect(find.text('Daily cricket quiz'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Bumrah'));
    await tester.pumpAndSettle();

    expect(find.textContaining('stories for “Bumrah”'), findsOneWidget);
    expect(find.textContaining('147 kph yorker'), findsWidgets);
  });

  testWidgets('profile filters saved stories and opens options',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.text('Saved stories'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    // Default bookmarks: two articles and one reel.
    await tester.tap(find.text('Reels 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Suryakumar'), findsOneWidget);
    expect(find.textContaining('Gill 104'), findsNothing);

    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Night mode'), findsOneWidget);
    expect(find.text('HD images'), findsOneWidget);
  });
}
