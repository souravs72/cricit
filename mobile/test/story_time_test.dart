import 'package:cricit/core/time/story_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('relative labels use IST and stay stable', () {
    final now = DateTime.utc(2026, 10, 28, 6, 0);
    expect(
      storyTimeLabel(DateTime.utc(2026, 10, 28, 5, 40), now: now),
      '20 min ago',
    );
    expect(
      storyTimeLabel(DateTime.utc(2026, 10, 28, 3, 0), now: now),
      '3 h ago',
    );
    expect(isFresh(DateTime.utc(2026, 10, 28, 4, 30), now: now), isTrue);
    expect(isFresh(DateTime.utc(2026, 10, 28, 3, 0), now: now), isFalse);
  });
}
