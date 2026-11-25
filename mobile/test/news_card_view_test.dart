import 'package:cricit/app/theme.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/news_card_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders headline, summary, source and team edge',
      (tester) async {
    final card = NewsCard(
      id: '1',
      kind: 'read',
      category: 'international',
      headline: 'Gill 104 keeps India in front at Perth',
      summary: 'Shubman Gill’s fifth Test hundred dragged India to 287 for 5.',
      publishedAt: DateTime.utc(2026, 10, 20, 11, 30),
      shareUrl: 'https://cricit.app/p/1',
      sourceName: 'ESPNcricinfo',
      tags: const ['India'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: SizedBox(
          width: 390,
          height: 844,
          child: NewsCardView(card: card),
        ),
      ),
    );

    expect(find.text('Gill 104 keeps India in front at Perth'), findsOneWidget);
    expect(find.textContaining('ESPNcricinfo'), findsOneWidget);
    expect(find.byTooltip('Share this card'), findsOneWidget);
  });

  testWidgets('a Nxtspot video card plays inline when tapped', (tester) async {
    final videoCard = NewsCard(
      id: 'video-card-1',
      kind: 'video',
      category: 'international',
      headline: 'Siraj four-fer rips through top order',
      summary: 'BCCI highlights.',
      publishedAt: DateTime.utc(2026, 10, 20, 11, 30),
      shareUrl: 'https://cricit.app/p/video-card-1',
      sourceName: 'BCCI',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: SizedBox(
          width: 390,
          height: 844,
          child: NewsCardView(card: videoCard, allowVideo: true),
        ),
      ),
    );

    expect(find.text('Play in App'), findsOneWidget);

    // Tap to play
    await tester.tap(find.text('Play in App'));
    await tester.pumpAndSettle();

    // Now EmbeddedYouTubePlayer is active and close button is visible
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap close to return to thumbnail
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Play in App'), findsOneWidget);
  });

  testWidgets(
      'an article card has no player and opens the original from the picture '
      'or the text', (tester) async {
    var opened = 0;
    final card = NewsCard(
      id: 'read-1',
      kind: 'video',
      category: 'domestic',
      headline: 'Baroda chase down 190 in the SMAT final',
      summary: 'Krunal Pandya’s 61 off 34 balls sealed the title.',
      publishedAt: DateTime.utc(2026, 10, 20, 11, 30),
      shareUrl: 'https://cricit.app/p/read-1',
      sourceName: 'Sportstar',
      url: 'https://sportstar.example/smat-final',
      videoId: 'xtn0lf5TY84',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: SizedBox(
          width: 390,
          height: 844,
          child: NewsCardView(card: card, onOpenSource: () => opened++),
        ),
      ),
    );

    expect(find.text('Play in App'), findsNothing);
    expect(find.text('Watch on YouTube ↗'), findsNothing);
    expect(find.textContaining('Sportstar'), findsWidgets);

    await tester.tap(find.text('Baroda chase down 190 in the SMAT final'));
    await tester.tap(find.byType(NewsCardView), warnIfMissed: false);
    await tester.tapAt(const Offset(195, 120)); // the picture header
    await tester.pumpAndSettle();
    expect(opened, 3);
  });
}
