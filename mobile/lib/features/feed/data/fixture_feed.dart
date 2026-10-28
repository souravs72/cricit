import '../domain/news_card.dart';

/// Local cards so the UI is complete when the API is down (dev / first run).
List<NewsCard> fixtureCards() {
  final now = DateTime.now().toUtc();
  return [
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000001',
      kind: 'read',
      category: 'international',
      headline: 'Gill 104 keeps India in front at Perth',
      headlineHi: 'गिल की 104 से पर्थ में भारत आगे',
      summary:
          'Shubman Gill’s fifth Test hundred dragged India to 287 for 5 after a two-hour rain break. He added 112 with Pant, then saw off Starc with the new ball. Australia still need seven wickets on a pitch that is starting to stay low.',
      summaryHi:
          'शुभमन गिल के पाँचवें टेस्ट शतक ने बारिश के बाद भारत को 287/5 तक पहुँचाया। पंत के साथ 112 रन की साझेदारी के बाद उन्होंने स्टार्क को नया गेंद के साथ रोका।',
      publishedAt: now.subtract(const Duration(minutes: 18)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000001',
      sourceName: 'ESPNcricinfo',
      url: 'https://www.espncricinfo.com/story/gill-perth',
      tags: const ['India', 'breaking'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000002',
      kind: 'video',
      category: 'international',
      headline: 'Bumrah’s yorker that bent the stumps',
      headlineHi: 'बुमराह की यॉर्कर जिसने स्टंप मोड़ दिए',
      summary:
          'The clip everyone sent around: a 147 kph yorker, late reverse, off stump cartwheeling. Channel 7 caught it from behind the bowler’s arm. Official upload only — we never re-host the video.',
      summaryHi:
          '147 किमी/घंटा की यॉर्कर, देर से रिवर्स, ऑफ स्टंप उखड़ा। आधिकारिक अपलोड ही चलाएँगे।',
      publishedAt: now.subtract(const Duration(hours: 1)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000002',
      sourceName: 'BCCI',
      videoId: 'dQw4w9wgGcQ',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000003',
      kind: 'read',
      category: 'domestic',
      headline: 'Mumbai take the lead after Jaiswal’s 178',
      headlineHi: 'जयसवाल के 178 के बाद मुंबई आगे',
      summary:
          'Yashasvi Jaiswal batted through the second day in the Ranji trophy semi-final at the Wankhede. Mumbai declared on 412 for 6. Tamil Nadu were 40 without loss at stumps, light fading over the western stand.',
      summaryHi:
          'रणजी सेमीफ़ाइनल में जयसवाल ने पूरे दूसरे दिन खेला। मुंबई ने 412/6 पर डिक्लेयर किया।',
      publishedAt: now.subtract(const Duration(hours: 3)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000003',
      sourceName: 'Cricbuzz',
      url: 'https://www.cricbuzz.com/story/jaiswal-ranji',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000004',
      kind: 'nxtspot',
      category: 'grassroots',
      headline: 'A 16-year-old takes 7 for 9 in Palakkad',
      headlineHi: 'पालक्काड़ में 16 साल के खिलाड़ी ने लिए 7 विकेट',
      summary:
          'Anjali Menon, opening the bowling for Palakkad District, took 7 for 9 in an under-19 game on a damp matting wicket. A parent filmed the hat-trick ball. Nxtspot is the first outlet to write it up.',
      summaryHi:
          'अंजलि मेनन ने अंडर-19 मैच में 7 विकेट लिए। हैट्रिक बॉल का वीडियो माता-पिता ने बनाया।',
      publishedAt: now.subtract(const Duration(hours: 5)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000004',
      sourceName: 'Nxtspot',
      tags: const ['Nxtspot'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000005',
      kind: 'read',
      category: 'international',
      headline: 'England rest Archer for the Oval ODI',
      headlineHi: 'इंग्लैंड ने ओवल वनडे से आर्चर को आराम दिया',
      summary:
          'Jofra Archer will skip Thursday’s match after scans showed tightness in his right side. England say it is precautionary. Woakes comes back into the eleven; the pitch is expected to be slow and used.',
      summaryHi:
          'जोफ्रा आर्चर गुरुवार का मैच छोड़ेंगे। इंग्लैंड कहता है यह सावधानी है। वोक्स वापस ग्यारह में हैं।',
      publishedAt: now.subtract(const Duration(hours: 8)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000005',
      sourceName: 'Sky Sports',
      url: 'https://www.skysports.com/cricket/england-archer',
      tags: const ['England'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000006',
      kind: 'read',
      category: 'domestic',
      headline: 'WPL: Knight Riders hold their nerve in a super over',
      headlineHi: 'डब्ल्यूपीएल: सुपर ओवर में नाइट राइडर्स जीतीं',
      summary:
          'Kolkata Knight Riders Women tied with Delhi in a rain-shortened league game, then won the super over by two runs. Mandhana’s 62 had looked enough until a last-over fumble at long-on.',
      summaryHi:
          'बारिश वाले मैच में टाई के बाद कोलकाता ने सुपर ओवर दो रन से जीता। मंधाना के 62 अधूरे रह गए।',
      publishedAt: now.subtract(const Duration(hours: 12)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000006',
      sourceName: 'Wisden',
      url: 'https://www.wisden.com/wpl-super-over',
      tags: const ['India'],
    ),
  ];
}

FeedPage fixturePage(String tab) {
  var cards = fixtureCards();
  switch (tab) {
    case 'video':
      cards = cards.where((c) => c.kind == 'video').toList();
    case 'domestic':
      cards = cards.where((c) => c.category == 'domestic').toList();
    case 'international':
      cards = cards.where((c) => c.category == 'international').toList();
    case 'nxtspot':
      cards = cards
          .where((c) => c.kind == 'nxtspot' || c.category == 'grassroots')
          .toList();
  }
  return FeedPage(cards, null);
}
