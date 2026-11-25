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

  testWidgets('tapping Play in App on video card starts embedded playback',
      (tester) async {
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
          child: NewsCardView(card: videoCard),
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
}
