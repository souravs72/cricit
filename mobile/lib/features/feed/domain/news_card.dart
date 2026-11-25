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
    this.ad,
    this.footerAd,
  });

  /// A full-page or sponsored-card ad slot, paged like any other card.
  factory NewsCard.fromAdSlot(AdSlot slot, int position) => NewsCard(
        id: 'ad-${slot.campaignId ?? 'house'}-$position',
        kind: 'ad',
        category: slot.format,
        headline: slot.title ?? '',
        summary: slot.body ?? '',
        publishedAt: DateTime.now().toUtc(),
        shareUrl: slot.clickUrl,
        image: slot.creative,
        url: slot.clickUrl,
        ad: slot,
      );

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
      ad: json['ad'] == null
          ? null
          : AdSlot.fromJson(json['ad'] as Map<String, dynamic>),
      footerAd: json['footer_ad'] == null
          ? null
          : AdSlot.fromJson(json['footer_ad'] as Map<String, dynamic>),
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
        if (ad != null) 'ad': ad!.toJson(),
        if (footerAd != null) 'footer_ad': footerAd!.toJson(),
      };

  /// Copy of this card with a footer ad docked under it.
  NewsCard withFooterAd(AdSlot slot) => NewsCard(
        id: id,
        kind: kind,
        category: category,
        headline: headline,
        summary: summary,
        headlineHi: headlineHi,
        summaryHi: summaryHi,
        publishedAt: publishedAt,
        shareUrl: shareUrl,
        image: image,
        videoId: videoId,
        sourceName: sourceName,
        url: url,
        tags: tags,
        ad: ad,
        footerAd: slot,
      );

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

  /// Set when this page is an ad (kind == 'ad').
  final AdSlot? ad;

  /// A slim sponsor banner shown at the foot of this card (brief: "ads as
  /// footer of the post").
  final AdSlot? footerAd;

  bool get isAd => kind == 'ad' && ad != null;
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
    final cards = <NewsCard>[];
    for (final item in items) {
      if (item['kind'] != 'ad') {
        cards.add(NewsCard.fromJson(item));
        continue;
      }
      final slot = AdSlot.fromJson(item);
      // AdMob native slots carry no creative of ours until the SDK lands
      // (T32); anything without a link has nothing to show.
      if (slot.clickUrl.isEmpty) continue;
      if (slot.format == 'footer') {
        // Dock under the story it follows; drop it if nothing precedes it.
        if (cards.isNotEmpty && !cards.last.isAd) {
          cards[cards.length - 1] = cards.last.withFooterAd(slot);
        }
      } else {
        cards.add(NewsCard.fromAdSlot(slot, cards.length));
      }
    }
    return FeedPage(cards, json['next_cursor'] as String?);
  }

  final List<NewsCard> cards;
  final String? nextCursor;
  final bool fromCache;
}

/// Mirrors backend app/schemas/feed.py `AdSlot`. AdMob native slots render
/// as sponsored cards until the AdMob SDK lands (T32).
class AdSlot {
  const AdSlot({
    required this.format,
    required this.clickUrl,
    this.campaignId,
    this.title,
    this.body,
    this.creative,
    this.advertiser,
  });

  factory AdSlot.fromJson(Map<String, dynamic> json) {
    final format = json['format'] as String? ?? 'sponsored_card';
    return AdSlot(
      format: format == 'admob_native' ? 'sponsored_card' : format,
      campaignId: json['campaign_id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      creative: json['creative'] as String?,
      clickUrl: json['click_url'] as String? ?? '',
      advertiser: json['advertiser'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': 'ad',
        'format': format,
        'campaign_id': campaignId,
        'title': title,
        'body': body,
        'creative': creative,
        'click_url': clickUrl,
        'advertiser': advertiser,
      };

  /// full_page | sponsored_card | footer
  final String format;
  final String? campaignId;
  final String? title;
  final String? body;
  final String? creative;
  final String clickUrl;
  final String? advertiser;

  bool get isFullPage => format == 'full_page';
}

/// Feed, Domestic and International are article decks: picture, headline,
/// summary, credit and a link to the original. Videos belong to the Videos
/// tab, and Nxtspot carries both its articles and its videos.
FeedPage shapeForTab(String tab, FeedPage page) {
  final bool Function(NewsCard) keep = switch (tab) {
    'video' => (c) => c.isVideo,
    'nxtspot' => (c) => true,
    _ => (c) => c.isAd || !c.isVideo,
  };
  return FeedPage(page.cards.where(keep).toList(), page.nextCursor);
}
