import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/settings/settings_controller.dart';
import '../data/feed_repository.dart';
import '../domain/news_card.dart';

enum FeedStatus { loading, data, empty, error }

class FeedSnapshot {
  const FeedSnapshot({
    this.status = FeedStatus.loading,
    this.cards = const [],
    this.nextCursor,
    this.fromCache = false,
    this.loadingMore = false,
    this.hasNewPosts = false,
    this.pendingNew = const [],
    this.errorMessage,
    this.pageIndex = 0,
  });

  final FeedStatus status;
  final List<NewsCard> cards;
  final String? nextCursor;
  final bool fromCache;
  final bool loadingMore;
  final bool hasNewPosts;
  final List<NewsCard> pendingNew;
  final String? errorMessage;
  final int pageIndex;

  FeedSnapshot copyWith({
    FeedStatus? status,
    List<NewsCard>? cards,
    String? nextCursor,
    bool? fromCache,
    bool? loadingMore,
    bool? hasNewPosts,
    List<NewsCard>? pendingNew,
    String? errorMessage,
    int? pageIndex,
    bool clearError = false,
  }) {
    return FeedSnapshot(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      nextCursor: nextCursor ?? this.nextCursor,
      fromCache: fromCache ?? this.fromCache,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNewPosts: hasNewPosts ?? this.hasNewPosts,
      pendingNew: pendingNew ?? this.pendingNew,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class FeedController extends Notifier<FeedSnapshot> {
  FeedController(this.tab);

  final String tab;

  @override
  FeedSnapshot build() {
    Future<void>.microtask(reload);
    return const FeedSnapshot();
  }

  FeedRepository get _repo => ref.read(feedRepositoryProvider);
  String get _lang => ref.read(settingsProvider).language;

  Future<void> reload() async {
    state = state.copyWith(status: FeedStatus.loading, clearError: true);
    try {
      final page = await _repo.fetch(tab: tab, lang: _lang);
      state = FeedSnapshot(
        status: page.cards.isEmpty ? FeedStatus.empty : FeedStatus.data,
        cards: page.cards,
        nextCursor: page.nextCursor,
        fromCache: page.fromCache,
      );
    } on ApiException catch (e) {
      state = state.copyWith(status: FeedStatus.error, errorMessage: e.message);
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repo.fetch(tab: tab, lang: _lang);
      if (state.pageIndex > 0 && page.cards.isNotEmpty) {
        state = state.copyWith(
          hasNewPosts: true,
          pendingNew: page.cards,
          fromCache: false,
        );
        return;
      }
      state = FeedSnapshot(
        status: page.cards.isEmpty ? FeedStatus.empty : FeedStatus.data,
        cards: page.cards,
        nextCursor: page.nextCursor,
      );
    } on ApiException catch (e) {
      if (state.cards.isEmpty) {
        state =
            state.copyWith(status: FeedStatus.error, errorMessage: e.message);
      }
    }
  }

  void revealNewPosts() {
    if (state.pendingNew.isEmpty) return;
    state = FeedSnapshot(
      status: FeedStatus.data,
      cards: state.pendingNew,
      nextCursor: state.nextCursor,
    );
  }

  void onPageChanged(int index) {
    state = state.copyWith(pageIndex: index);
    if (state.nextCursor != null &&
        !state.loadingMore &&
        index >= state.cards.length - 5) {
      Future.microtask(loadMore);
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.fetch(tab: tab, lang: _lang, cursor: cursor);
      state = state.copyWith(
        cards: [...state.cards, ...page.cards],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } on ApiException {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final feedControllerProvider =
    NotifierProvider.family<FeedController, FeedSnapshot, String>(
  FeedController.new,
);
