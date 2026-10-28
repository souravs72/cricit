/// Timestamps are UTC on the wire. Display in IST (UTC+05:30).
const istOffset = Duration(hours: 5, minutes: 30);

DateTime toIst(DateTime utc) => utc.toUtc().add(istOffset);

String storyTimeLabel(DateTime publishedAt, {DateTime? now}) {
  final published = toIst(publishedAt);
  final current = toIst(now ?? DateTime.now().toUtc());
  final delta = current.difference(published);
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  if (delta.inHours < 48) return 'Yesterday';
  return '${published.day} ${_month(published.month)}';
}

bool isFresh(DateTime publishedAt, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc();
  return current.difference(publishedAt.toUtc()) < const Duration(hours: 2);
}

String _month(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[m - 1];
}
