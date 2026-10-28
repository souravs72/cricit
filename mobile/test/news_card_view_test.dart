import 'package:cricit/app/theme.dart';
import 'package:cricit/features/feed/domain/news_card.dart';
import 'package:cricit/features/feed/presentation/news_card_view.dart';
import 'package:flutter/material.dart';
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
}
