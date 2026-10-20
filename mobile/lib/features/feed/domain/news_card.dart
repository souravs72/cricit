/// Mirrors backend app/schemas/feed.py `Card`. T21 may move this to Freezed.
class NewsCard {
  const NewsCard({
    required this.id,
    required this.kind,
    required this.category,
    required this.headline,
    required this.summary,
    required this.publishedAt,
    required this.shareUrl,
    this.image,
    this.videoId,
    this.sourceName,
    this.url,
    this.tags = const [],
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>?;
    return NewsCard(
      id: json['id'] as String,
      kind: json['kind'] as String,
      category: json['category'] as String,
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      shareUrl: json['share_url'] as String,
      image: json['image'] as String?,
      videoId: json['video_id'] as String?,
      sourceName: source?['name'] as String?,
      url: json['url'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  final String id;
  final String kind;
  final String category;
  final String headline;
  final String summary;
  final DateTime publishedAt;
  final String shareUrl;
  final String? image;
  final String? videoId;
  final String? sourceName;
  final String? url;
  final List<String> tags;
}

class FeedPage {
  const FeedPage(this.cards, this.nextCursor);

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    return FeedPage(
      // Ad slots (kind == 'ad') are rendered by T32; skip them until then.
      items.where((i) => i['kind'] != 'ad').map(NewsCard.fromJson).toList(),
      json['next_cursor'] as String?,
    );
  }

  final List<NewsCard> cards;
  final String? nextCursor;
}
