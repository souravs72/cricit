import '../domain/news_card.dart';

/// Local cricket cards and video shorts so the UI is 100% complete and responsive.
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
          'शुभमन गिल के पाँचवें टेस्ट शतक ने बारिश के बाद भारत को 287/5 तक पहुँचाया। पंत के साथ 112 रन की साझेदारी के बाद उन्होंने स्टार्क को नई गेंद के साथ संभाला।',
      publishedAt: now.subtract(const Duration(minutes: 18)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000001',
      sourceName: 'ESPNcricinfo',
      image:
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80',
      url: 'https://www.espncricinfo.com/story/gill-perth',
      tags: const ['India', 'breaking'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000002',
      kind: 'video',
      category: 'international',
      headline: 'Bumrah’s 147 kph yorker that bent the stumps',
      headlineHi: 'बुमराह की यॉर्कर जिसने स्टंप मोड़ दिए',
      summary:
          'The clip everyone shared: a 147 kph reverse-swinging yorker that uprooted the off-stump at Perth. Channel 7 broadcast caught it from behind the bowler’s arm. Official upload from BCCI YouTube.',
      summaryHi:
          '147 किमी/घंटा की यॉर्कर, देर से रिवर्स, ऑफ स्टंप उखड़ा। आधिकारिक प्रसारण क्लिप।',
      publishedAt: now.subtract(const Duration(hours: 1)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000002',
      sourceName: 'BCCI YouTube',
      image: 'https://i.ytimg.com/vi/xtn0lf5TY84/hqdefault.jpg',
      videoId: 'xtn0lf5TY84',
      url: 'https://www.youtube.com/shorts/xtn0lf5TY84',
      tags: const ['India', 'Bumrah'],
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
      image:
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=1200&q=80',
      url: 'https://www.cricbuzz.com/cricket-news',
      tags: const ['India', 'Ranji'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000004',
      kind: 'nxtspot',
      category: 'grassroots',
      headline: '16-year-old spinner claims 7 wickets in Palakkad District U-19 match',
      headlineHi: 'पालक्काड़ में 16 साल की खिलाड़ी ने लिए 7 विकेट',
      summary:
          'Anjali Menon, opening the bowling for Palakkad District, took 7 for 9 in an under-19 game on a damp matting wicket. A parent filmed the hat-trick ball. Nxtspot brings you grassroot talent nobody else covers.',
      summaryHi:
          'अंजलि मेनन ने अंडर-19 मैच में 7 विकेट लिए। हैट्रिक बॉल का वीडियो माता-पिता ने बनाया। ग्रासरूट क्रिकेट की नई पहचान।',
      publishedAt: now.subtract(const Duration(hours: 5)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000004',
      sourceName: 'Nxtspot Grassroots',
      image:
          'https://images.unsplash.com/photo-1593341646782-e0b495cff52a?auto=format&fit=crop&w=1200&q=80',
      tags: const ['Nxtspot', 'Grassroots'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000005',
      kind: 'read',
      category: 'international',
      headline: 'England rest Archer for the Oval ODI against West Indies',
      headlineHi: 'इंग्लैंड ने ओवल वनडे से आर्चर को आराम दिया',
      summary:
          'Jofra Archer will skip Thursday’s match after scans showed tightness in his right side. England medical staff confirmed the decision is precautionary. Chris Woakes returns to the playing eleven.',
      summaryHi:
          'जोफ्रा आर्चर गुरुवार का मैच छोड़ेंगे। इंग्लैंड ने इसे एहतियातन बताया। क्रिस वोक्स वापस एकादश में शामिल।',
      publishedAt: now.subtract(const Duration(hours: 8)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000005',
      sourceName: 'BBC Sport Cricket',
      image:
          'https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=1200&q=80',
      url: 'https://feeds.bbci.co.uk/sport/cricket/rss.xml',
      tags: const ['England'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000006',
      kind: 'video',
      category: 'domestic',
      headline: 'Virat Kohli’s masterclass nets session in Perth',
      headlineHi: 'पर्थ में विराट कोहली का अभ्यास सत्र',
      summary:
          'Exclusive nets footage of Virat Kohli refining his front-foot stride against left-arm pace ahead of the opening Border-Gavaskar Test. Uploaded by Cricbuzz Shorts.',
      summaryHi:
          'पर्थ में बॉर्डर-गावस्कर टेस्ट से पहले विराट कोहली का शानदार अभ्यास सत्र। क्रिकबज शॉर्ट्स से विशेष वीडियो।',
      publishedAt: now.subtract(const Duration(hours: 10)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000006',
      sourceName: 'Cricbuzz Shorts',
      image: 'https://i.ytimg.com/vi/zkXTEiNYtm8/hqdefault.jpg',
      videoId: 'zkXTEiNYtm8',
      url: 'https://www.youtube.com/shorts/zkXTEiNYtm8',
      tags: const ['India', 'Kohli'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000007',
      kind: 'read',
      category: 'domestic',
      headline: 'IPL 2026: CSK go into the Mega Auction with the biggest purse',
      headlineHi: 'आईपीएल: सीएसके के पास नीलामी में सबसे बड़ा पर्स',
      summary:
          'Chennai Super Kings confirmed a remaining purse of ₹48 crore following strategic retentions. Mumbai Indians and KKR have finalized their retained squads ahead of next month’s auction.',
      summaryHi:
          'चेन्नई सुपर किंग्स के पास ₹48 करोड़ का पर्स उपलब्ध है। मुंबई इंडियंस और केकेआर ने अपनी रिटेंशन सूची को अंतिम रूप दिया।',
      publishedAt: now.subtract(const Duration(hours: 12)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000007',
      sourceName: 'Times of India Cricket',
      image:
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80',
      url: 'https://timesofindia.indiatimes.com/sports/cricket',
      tags: const ['CSK', 'IPL'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000008',
      kind: 'read',
      category: 'international',
      headline: 'BCCI on X: Team India Test squad announced for Australia series',
      headlineHi: 'बीसीसीआई एक्स अपडेट: ऑस्ट्रेलिया सीरीज के लिए भारतीय टीम घोषित',
      summary:
          'The Senior Men’s Selection Committee announced an 18-member squad with Jasprit Bumrah as vice-captain. Rohit Sharma will lead the team across the five-Test series.',
      summaryHi:
          'सीनियर चयन समिति ने 18 सदस्यीय टीम की घोषणा की, बुमराह उपकप्तान होंगे। रोहित शर्मा 5 मैचों की सीरीज में टीम की अगुवाई करेंगे।',
      publishedAt: now.subtract(const Duration(hours: 14)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000008',
      sourceName: 'BCCI on X',
      image:
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=1200&q=80',
      url: 'https://x.com/BCCI',
      tags: const ['India', 'BCCI'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000009',
      kind: 'video',
      category: 'domestic',
      headline: 'Rohit Sharma’s signature pull shot in slow motion',
      headlineHi: 'रोहित शर्मा का प्रसिद्ध पुल शॉट स्लो मोशन में',
      summary:
          'Watch the sublime balance and swivel as Rohit Sharma dispatches a 145 kph bouncer over deep square leg. Uploaded by Sportskeeda Cricket Shorts.',
      summaryHi:
          'रोहित शर्मा का ट्रेडमार्क पुल शॉट जिसने गेंद को डीप स्क्वायर लेग के पार पहुंचाया। स्पोर्ट्सकीड़ा क्रिकेट शॉर्ट्स।',
      publishedAt: now.subtract(const Duration(hours: 16)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000009',
      sourceName: 'Sportskeeda Shorts',
      image: 'https://i.ytimg.com/vi/Ebn_cgfSA2w/hqdefault.jpg',
      videoId: 'Ebn_cgfSA2w',
      url: 'https://www.youtube.com/shorts/Ebn_cgfSA2w',
      tags: const ['India', 'Rohit'],
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
