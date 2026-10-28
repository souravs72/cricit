import 'package:cricit/app/app.dart';
import 'package:cricit/features/feed/data/feed_repository.dart';
import 'package:cricit/features/feed/data/fixture_feed.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InstantFeedRepository extends FeedRepository {
  _InstantFeedRepository()
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
  testWidgets('shows welcome after bootstrap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: CricitApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('CRICIT'), findsWidgets);
    expect(find.textContaining('Skip for now'), findsOneWidget);
  });

  testWidgets('skip for now opens the home feed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWith(
            (ref) => _InstantFeedRepository(),
          ),
        ],
        child: const CricitApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('My feed'), findsOneWidget);
    expect(find.text('Gill 104 keeps India in front at Perth'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
