import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env.dart';
import '../../../core/api/api_client.dart';
import '../../../core/cache/feed_cache.dart';
import '../domain/news_card.dart';
import 'fixture_feed.dart';

class FeedRepository {
  FeedRepository(this._dio, {FeedCache? cache}) : _cache = cache ?? FeedCache();

  final Dio _dio;
  final FeedCache _cache;

  Future<FeedPage> fetch({
    String tab = 'feed',
    String lang = 'en',
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/v1/feed',
        queryParameters: {
          'tab': tab == 'video' ? 'feed' : tab,
          'lang': lang,
          if (cursor != null) 'cursor': cursor,
        },
      );
      var page = FeedPage.fromJson(res.data!);
      if (tab == 'video') {
        page = FeedPage(
          page.cards.where((c) => c.isVideo).toList(),
          page.nextCursor,
        );
      }
      if (cursor == null) {
        await _cache.write(tab, lang, page);
      }
      if (page.cards.isEmpty && cursor == null && !Env.isProd) {
        return fixturePage(tab);
      }
      return page;
    } on DioException catch (e) {
      if (cursor == null) {
        final cached = await _cache.read(tab, lang);
        if (cached != null) return cached;
        if (!Env.isProd) return fixturePage(tab);
      }
      throw toApiException(e);
    }
  }

  Future<List<NewsCard>> search(String query, {String lang = 'en'}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/v1/search',
        queryParameters: {'q': query, 'lang': lang},
      );
      return FeedPage.fromJson(res.data!).cards;
    } on DioException {
      final cached = await _cache.read('feed', lang);
      final pool = [...?cached?.cards, ...fixtureCards()];
      return pool.where((c) {
        final hay =
            '${c.headline} ${c.summary} ${c.tags.join(' ')} ${c.headlineHi ?? ''}'
                .toLowerCase();
        return hay.contains(q);
      }).toList();
    }
  }
}

final feedRepositoryProvider =
    Provider((ref) => FeedRepository(ref.watch(dioProvider)));
