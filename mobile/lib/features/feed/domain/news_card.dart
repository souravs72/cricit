/// Mirrors backend app/schemas/feed.py `Card`.
class NewsCard {
  const NewsCard({
    required this.id,
    required this.kind,
    required this.category,
    required this.headline,
    required this.summary,
    required this.publishedAt,
    required this.shareUrl,
    this.headlineHi,
    this.summaryHi,
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
      headlineHi: json['headline_hi'] as String?,
      summaryHi: json['summary_hi'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      shareUrl: json['share_url'] as String,
      image: json['image'] as String?,
      videoId: json['video_id'] as String?,
      sourceName: source?['name'] as String?,
      url: json['url'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'category': category,
        'headline': headline,
        'summary': summary,
        'headline_hi': headlineHi,
        'summary_hi': summaryHi,
        'published_at': publishedAt.toUtc().toIso8601String(),
        'share_url': shareUrl,
        'image': image,
        'video_id': videoId,
        'source': sourceName == null ? null : {'name': sourceName},
        'url': url,
        'tags': tags,
      };

  final String id;
  final String kind;
  final String category;
  final String headline;
  final String summary;
  final String? headlineHi;
  final String? summaryHi;
  final DateTime publishedAt;
  final String shareUrl;
  final String? image;
  final String? videoId;
  final String? sourceName;
  final String? url;
  final List<String> tags;

  bool get isVideo => kind == 'video' && videoId != null;
  bool get isBreaking => tags.any((t) => t.toLowerCase() == 'breaking');
  bool get hasHindi => headlineHi != null && summaryHi != null;

  String headlineFor({required bool hindi}) =>
      hindi && headlineHi != null ? headlineHi! : headline;
  String summaryFor({required bool hindi}) =>
      hindi && summaryHi != null ? summaryHi! : summary;
}

class FeedPage {
  const FeedPage(this.cards, this.nextCursor, {this.fromCache = false});

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    return FeedPage(
      items.where((i) => i['kind'] != 'ad').map(NewsCard.fromJson).toList(),
      json['next_cursor'] as String?,
    );
  }

  final List<NewsCard> cards;
  final String? nextCursor;
  final bool fromCache;
}
