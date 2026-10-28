import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/domain/news_card.dart';

/// Last 50 cards per tab, shown instantly offline. Drift (T27) can replace this later.
class FeedCache {
  FeedCache([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _store() async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _key(String tab, String lang) => 'feed_cache_${tab}_$lang';

  Future<void> write(String tab, String lang, FeedPage page) async {
    final prefs = await _store();
    final cards = page.cards.take(50).map((c) => c.toJson()).toList();
    await prefs.setString(
      _key(tab, lang),
      jsonEncode({
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'next_cursor': page.nextCursor,
        'cards': cards,
      }),
    );
  }

  Future<FeedPage?> read(String tab, String lang) async {
    final prefs = await _store();
    final raw = prefs.getString(_key(tab, lang));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cards = (json['cards'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(NewsCard.fromJson)
          .toList();
      if (cards.isEmpty) return null;
      return FeedPage(cards, json['next_cursor'] as String?, fromCache: true);
    } on FormatException {
      return null;
    }
  }
}
