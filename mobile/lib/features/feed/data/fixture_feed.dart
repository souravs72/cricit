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
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000007',
      kind: 'read',
      category: 'international',
      headline: "Kohli's 82 not out finishes the Vizag chase",
      headlineHi: 'कोहली के नाबाद 82 से विजाग में पीछा पूरा',
      summary:
          'India hunted 278 with 11 balls to spare. Kohli’s 82 off 74 was the calm innings after early wickets. Hardik hit the winning six over cover.',
      summaryHi:
          'भारत ने 278 का पीछा 11 गेंद पहले पूरा किया। कोहली का 82 शांत पारी रहा।',
      publishedAt: now.subtract(const Duration(hours: 14)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000007',
      sourceName: 'ESPNcricinfo',
      url: 'https://www.espncricinfo.com/story/kohli-82-vizag',
      image:
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=1400&q=80',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000008',
      kind: 'read',
      category: 'domestic',
      headline: 'BCCI names central contracts: Gill in grade A',
      headlineHi: 'बीसीसीआई सेंट्रल कॉन्ट्रैक्ट: गिल ग्रेड ए में',
      summary:
          'Shubman Gill moves into Grade A. Bumrah stays at the top of the list. Mandhana and Harmanpreet remain Grade A on the women’s side.',
      summaryHi: 'शुभमन गिल ग्रेड ए में आए। बुमराह सूची में सबसे ऊपर रहे।',
      publishedAt: now.subtract(const Duration(hours: 16)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000008',
      sourceName: 'BCCI',
      url: 'https://www.bcci.tv/news/central-contracts',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000009',
      kind: 'video',
      category: 'international',
      headline: "Pant's reverse-scoop off Starc, all angles",
      headlineHi: 'पंत का स्टार्क पर रिवर्स स्कूप, हर एंगल',
      summary:
          'Official BCCI upload: four camera angles of Pant’s reverse-scoop for six off Starc in the last over before lunch. Audio from the stump mic stays on.',
      summaryHi:
          'आधिकारिक बीसीसीआई अपलोड: लंच से पहले पंत का छक्का चार कैमरों से।',
      publishedAt: now.subtract(const Duration(hours: 18)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000009',
      sourceName: 'BCCI',
      videoId: 'official',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000010',
      kind: 'read',
      category: 'international',
      headline: 'Bumrah back to number one in the ICC Test rankings',
      headlineHi: 'आईसीसी टेस्ट रैंकिंग में बुमराह फिर नंबर एक',
      summary:
          'Jasprit Bumrah reclaimed the top spot after Perth. Cummins drops to third. Gill is up to six among batters.',
      summaryHi: 'पर्थ के बाद बुमराह शीर्ष पर लौटे। कमिंस तीसरे स्थान पर आए।',
      publishedAt: now.subtract(const Duration(hours: 20)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000010',
      sourceName: 'ICC',
      url: 'https://www.icc-cricket.com/rankings',
      tags: const ['India', 'ICC'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000011',
      kind: 'nxtspot',
      category: 'grassroots',
      headline: 'Jorhat school batter hits 164 off 88 in a 30-over game',
      headlineHi: 'जोरहाट स्कूल की बल्लेबाज़ ने 88 गेंद पर 164 बनाए',
      summary:
          'Meera Sharma, 17, struck 164 off 88 for Jorhat Town School against a district XI. Fourteen sixes, most over midwicket.',
      summaryHi: 'मीरा शर्मा ने जिला XI के खिलाफ 14 छक्के लगाए।',
      publishedAt: now.subtract(const Duration(hours: 22)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000011',
      sourceName: 'Nxtspot',
      tags: const ['Nxtspot'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000012',
      kind: 'nxtspot',
      category: 'grassroots',
      headline: 'Imphal women win their first state T20 by 41 runs',
      headlineHi: 'इंफाल की महिला टीम ने पहला राज्य टी20 जीता',
      summary:
          'Manipur’s senior women beat Nagaland by 41 in Imphal. Captain Linthoi’s 3 for 19 closed it. About four hundred people stood around the boundary.',
      summaryHi: 'मणिपुर की सीनियर महिला टीम नागालैंड से 41 रन से जीती।',
      publishedAt: now.subtract(const Duration(hours: 26)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000012',
      sourceName: 'Nxtspot',
      tags: const ['Nxtspot'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000013',
      kind: 'read',
      category: 'domestic',
      headline: 'RCB retain Kohli; Green and Patidar stay too',
      headlineHi: 'आरसीबी ने कोहली को रखा, ग्रीन और पाटीदार भी',
      summary:
          'Royal Challengers Bengaluru kept Virat Kohli, Cameron Green and Rajat Patidar. They will go to the auction short of a death bowler.',
      summaryHi:
          'रॉयल चैलेंजर्स बेंगलुरु ने विराट कोहली, कैमरून ग्रीन और रजत पाटीदार को रोका।',
      publishedAt: now.subtract(const Duration(hours: 28)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000013',
      sourceName: 'IPL',
      url: 'https://www.iplt20.com/news/rcb-retain',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000014',
      kind: 'video',
      category: 'domestic',
      headline: 'Dhoni in the CSK nets, one stump, 12 balls',
      headlineHi: 'चेपौक नेट में धोनी, एक स्टंप, 12 गेंदें',
      summary:
          'Official IPL clip: MS Dhoni facing 12 balls at a single stump in the Chepauk nets. Three pick up over midwicket.',
      summaryHi: 'आधिकारिक आईपीएल क्लिप: धोनी ने 12 गेंदों का सामना किया।',
      publishedAt: now.subtract(const Duration(hours: 30)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000014',
      sourceName: 'IPL',
      videoId: 'official',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000015',
      kind: 'read',
      category: 'international',
      headline: 'Cummins to miss the Adelaide Test with a hamstring strain',
      headlineHi: 'कमिन्स हैमस्ट्रिंग की चोट से एडिलेड टेस्ट चूकेंगे',
      summary:
          'Pat Cummins felt tightness walking off on day four in Perth. Scans in Sydney showed a grade-one strain. Starc will lead.',
      summaryHi:
          'पर्थ के चौथे दिन कमिंस को खिंचाव महसूस हुआ। स्टार्क कप्तानी करेंगे।',
      publishedAt: now.subtract(const Duration(hours: 32)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000015',
      sourceName: 'BBC Sport',
      url: 'https://www.bbc.com/sport/cricket/cummins',
      tags: const ['Australia'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000016',
      kind: 'nxtspot',
      category: 'grassroots',
      headline: 'Ranchi under-19 spinner takes 6 for 11 on red soil',
      headlineHi: 'राँची अंडर-19 स्पिनर ने लिए 6 विकेट',
      summary:
          'A 19-year-old off-spinner from Ranchi took 6 for 11 in the Jharkhand inter-district. Two of the wickets were stumped down the leg side.',
      summaryHi: 'झारखंड इंटर-डिस्ट्रिक्ट में ऑफ स्पिनर ने 6/11 लिए।',
      publishedAt: now.subtract(const Duration(hours: 34)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000016',
      sourceName: 'Nxtspot',
      tags: const ['Nxtspot'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000017',
      kind: 'read',
      category: 'domestic',
      headline: "KKR snatch a last-over win after Russell's 28-ball 62",
      headlineHi: 'रसेल के 28 गेंद के 62 से केकेआर की आखिरी ओवर जीत',
      summary:
          'Andre Russell’s 62 off 28 took KKR from 121 for 6 to 181. Punjab Kings needed 16 off the last over and managed 11.',
      summaryHi:
          'आंद्रे रसेल के 62 ने केकेआर को 181 तक पहुँचाया। पंजाब 11 रन से हारा।',
      publishedAt: now.subtract(const Duration(hours: 36)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000017',
      sourceName: 'IPL',
      url: 'https://www.iplt20.com/news/kkr-russell',
      tags: const ['India'],
    ),
    NewsCard(
      id: '0192f1a0-0000-7000-8000-000000000018',
      kind: 'video',
      category: 'international',
      headline: "Gill's cover drive, 24 frames, no sound",
      headlineHi: 'गिल का कवर ड्राइव, 24 फ्रेम, बिना आवाज़',
      summary:
          'Official BCCI short: Gill’s cover drive off Cummins in the first over after tea. Twenty-four frames, no commentary.',
      summaryHi:
          'आधिकारिक बीसीसीआई शॉर्ट: चाय के बाद कमिंस की गेंद पर गिल का कवर ड्राइव।',
      publishedAt: now.subtract(const Duration(hours: 38)),
      shareUrl: 'https://cricit.app/p/0192f1a0-0000-7000-8000-000000000018',
      sourceName: 'BCCI',
      videoId: 'official',
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
