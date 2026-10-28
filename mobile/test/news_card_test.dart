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
}
