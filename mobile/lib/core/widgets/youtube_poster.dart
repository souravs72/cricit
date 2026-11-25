/// Poster frame for a YouTube video. One URL everywhere (feed precache,
/// reel poster, card hero) so they all share one image-cache entry.
String youTubePosterUrl(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
