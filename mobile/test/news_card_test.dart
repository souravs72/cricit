import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the backend card shape and skips ad slots', () {
    final page = FeedPage.fromJson({
      'items': [
        {
          'id': '0192f1a0-0000-7000-8000-000000000001',
          'kind': 'read',
          'category': 'international',
          'headline': 'Gill 104 powers India',
          'summary': 'India scored 287 for 5.',
          'headline_hi': 'गिल की 104',
          'summary_hi': 'भारत ने 287/5 बनाए।',
          'source': {'name': 'ESPNcricinfo'},
          'url': 'https://example.com/a',
          'tags': ['India', 'Shubman Gill'],
          'published_at': '2026-10-20T11:30:00Z',
          'share_url': 'https://cricit.app/p/0192f1a0',
        },
        {'kind': 'ad', 'format': 'admob_native'},
      ],
      'next_cursor': 'abc',
    });

    expect(page.cards, hasLength(1));
    expect(page.cards.first.sourceName, 'ESPNcricinfo');
    expect(page.cards.first.tags, contains('India'));
    expect(page.nextCursor, 'abc');
    expect(page.cards.first.headlineFor(hindi: true), 'गिल की 104');
    expect(page.cards.first.toJson()['id'], page.cards.first.id);
  });

  test('turns ad slots into ad pages and docks footer ads', () {
    Map<String, dynamic> card(String id) => {
          'id': id,
          'kind': 'read',
          'category': 'domestic',
          'headline': 'h $id',
          'summary': 's',
          'tags': <String>[],
          'published_at': '2026-10-20T11:30:00Z',
          'share_url': 'https://cricit.app/p/$id',
        };
    final page = FeedPage.fromJson({
      'items': [
        card('a'),
        {
          'kind': 'ad',
          'format': 'footer',
          'title': 'Alerts',
          'click_url': 'https://example.com/f',
        },
        card('b'),
        {
          'kind': 'ad',
          'format': 'full_page',
          'campaign_id': 'c1',
          'title': 'Big',
          'click_url': 'https://example.com/p',
        },
      ],
    });

    expect(page.cards.map((c) => c.isAd), [false, false, true]);
    expect(page.cards.first.footerAd?.title, 'Alerts');
    expect(page.cards.last.ad?.isFullPage, isTrue);
    // Round-trips through the offline cache.
    final again = NewsCard.fromJson(page.cards.last.toJson());
    expect(again.isAd, isTrue);
    expect(NewsCard.fromJson(page.cards.first.toJson()).footerAd, isNotNull);
  });

  test('article tabs drop videos, Nxtspot keeps them, Videos keeps only them',
      () {
    NewsCard c(String id, String kind) => NewsCard(
          id: id,
          kind: kind,
          category: 'grassroots',
          headline: id,
          summary: '',
          publishedAt: DateTime.utc(2026, 11, 25),
          shareUrl: 'https://cricit.app/p/$id',
          videoId: kind == 'video' ? 'abc' : null,
        );
    final page =
        FeedPage([c('a', 'read'), c('v', 'video'), c('n', 'nxtspot')], null);
    List<String> ids(String tab) =>
        shapeForTab(tab, page).cards.map((e) => e.id).toList();
    expect(ids('feed'), ['a', 'n']);
    expect(ids('domestic'), ['a', 'n']);
    expect(ids('international'), ['a', 'n']);
    expect(ids('nxtspot'), ['a', 'v', 'n']);
    expect(ids('video'), ['v']);
  });
}
