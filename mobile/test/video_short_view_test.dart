import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/video_short_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VideoShortView renders screenwide layout with video, headline and channel',
      (tester) async {
    final card = NewsCard(
      id: 'test-video-1',
      kind: 'video',
      category: 'international',
      headline: 'Bumrah yorker swings late to shatter the off-stump',
      summary: 'BCCI official highlights from the Perth test match.',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-1',
      sourceName: 'BCCI Official',
      videoId: 'xtn0lf5TY84',
      tags: const ['India', 'Bumrah'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 932,
            child: VideoShortView(card: card),
          ),
        ),
      ),
    );

    expect(find.text('BCCI Official'), findsOneWidget);
    expect(
      find.text('Bumrah yorker swings late to shatter the off-stump'),
      findsOneWidget,
    );
    expect(find.text('Watch on YouTube ↗'), findsOneWidget);
    expect(find.text('CRICIT VIDEO'), findsOneWidget);
  });

  testWidgets('swiping left on VideoShortView triggers onSwipeNext', (tester) async {
    bool nextTriggered = false;
    bool prevTriggered = false;

    final card = NewsCard(
      id: 'test-video-2',
      kind: 'video',
      category: 'international',
      headline: 'Kohli boundary counter against Starc',
      summary: 'BCCI highlights from Perth.',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-2',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 932,
            child: VideoShortView(
              card: card,
              onSwipeNext: () => nextTriggered = true,
              onSwipePrevious: () => prevTriggered = true,
            ),
          ),
        ),
      ),
    );

    // Swipe left (drag from x=300 to x=50, negative delta)
    await tester.drag(find.byType(VideoShortView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(nextTriggered, isTrue);

    // Swipe right (drag from x=100 to x=350, positive delta)
    await tester.drag(find.byType(VideoShortView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(prevTriggered, isTrue);
  });
}
