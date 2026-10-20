import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/news_card.dart';

class FeedRepository {
  FeedRepository(this._dio);

  final Dio _dio;

  /// T27 adds the Drift cache: return cached cards first, then refresh.
  Future<FeedPage> fetch({String tab = 'feed', String lang = 'en', String? cursor}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/v1/feed',
        queryParameters: {'tab': tab, 'lang': lang, if (cursor != null) 'cursor': cursor},
      );
      return FeedPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final feedRepositoryProvider = Provider((ref) => FeedRepository(ref.watch(dioProvider)));

final feedProvider = FutureProvider.family<FeedPage, String>((ref, tab) {
  return ref.watch(feedRepositoryProvider).fetch(tab: tab);
});
