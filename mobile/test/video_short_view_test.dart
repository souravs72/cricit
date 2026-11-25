import 'package:cricit/core/widgets/embedded_youtube_player.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/video_short_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'VideoShortView renders screenwide layout with video, headline and channel',
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
    expect(find.text('Reel Fill'), findsOneWidget);
  });

  testWidgets(
      'tapping Reel Fill toggle switches between reel cover and fit view',
      (tester) async {
    final card = NewsCard(
      id: 'test-video-toggle',
      kind: 'video',
      category: 'international',
      headline: 'Bumrah magic delivery',
      summary: 'Perth test match wicket.',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-toggle',
      videoId: 'xtn0lf5TY84',
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

    // Initial state has 'Reel Fill'
    expect(find.text('Reel Fill'), findsOneWidget);

    // Tap toggle button to switch to Fit Video
    await tester.tap(find.text('Reel Fill'));
    await tester.pumpAndSettle();

    expect(find.text('Fit Video'), findsOneWidget);

    // Tap again to switch back to Reel Fill
    await tester.tap(find.text('Fit Video'));
    await tester.pumpAndSettle();

    expect(find.text('Reel Fill'), findsOneWidget);
  });

  testWidgets('tapping video canvas toggles play and pause', (tester) async {
    final card = NewsCard(
      id: 'test-video-tap',
      kind: 'video',
      category: 'international',
      headline: 'Bumrah magic delivery',
      summary: 'Perth test match wicket.',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-tap',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 932,
            child: VideoShortView(card: card, isActive: true),
          ),
        ),
      ),
    );

    // Initial state: playing, no pause overlay
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tap center of VideoShortView
    await tester.tap(find.byType(VideoShortView));
    // Must advance past kDoubleTapTimeout (300ms) because onDoubleTap is registered
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Now paused: play arrow overlay should appear
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap again to resume
    await tester.tap(find.byType(VideoShortView));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('swiping left on VideoShortView triggers onSwipeNext',
      (tester) async {
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

  testWidgets('finishing a reel advances to the next one (auto-scroll)',
      (tester) async {
    var nextCount = 0;
    final card = NewsCard(
      id: 'test-video-end',
      kind: 'video',
      category: 'international',
      headline: 'Auto advance',
      summary: '',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-end',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 932,
            child: VideoShortView(card: card, onSwipeNext: () => nextCount++),
          ),
        ),
      ),
    );

    final player = tester.widget<EmbeddedYouTubePlayer>(
      find.byType(EmbeddedYouTubePlayer),
    );
    expect(player.autoPlay, isTrue);
    player.onEnded!();
    expect(nextCount, 1);
  });

  testWidgets('poster-only reel creates no video player', (tester) async {
    final card = NewsCard(
      id: 'test-video-poster',
      kind: 'video',
      category: 'international',
      headline: 'Poster only',
      summary: '',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-poster',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 932,
            child: VideoShortView(card: card, keepPlayer: false),
          ),
        ),
      ),
    );

    expect(find.byType(EmbeddedYouTubePlayer), findsNothing);
    expect(find.text('Poster only'), findsOneWidget);
  });

  testWidgets('overlay is hidden until the reel settles on screen',
      (tester) async {
    final card = NewsCard(
      id: 'test-video-chrome',
      kind: 'video',
      category: 'international',
      headline: 'Arriving reel',
      summary: '',
      publishedAt: DateTime.now().toUtc(),
      shareUrl: 'https://cricit.app/p/test-video-chrome',
      videoId: 'xtn0lf5TY84',
    );

    Future<double> headlineOpacity(double visibility) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 430,
              height: 932,
              child: VideoShortView(card: card, chromeVisibility: visibility),
            ),
          ),
        ),
      );
      final opacity = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.text('Arriving reel'),
          matching: find.byType(Opacity),
        ),
      );
      return opacity.isEmpty ? 1 : opacity.first.opacity;
    }

    expect(await headlineOpacity(0), 0);
    expect(await headlineOpacity(1), 1);
  });
}
