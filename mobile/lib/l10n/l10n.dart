import 'package:flutter/widgets.dart';

/// UI copy for en/hi. ARB files in this folder are the source list (T33 gen-l10n).
class L10n {
  const L10n(this.locale);

  final Locale locale;

  bool get isHindi => locale.languageCode == 'hi';

  static L10n of(BuildContext context) {
    return L10n(Localizations.localeOf(context));
  }

  String get appName => isHindi ? 'क्रिकिट' : 'CRICIT';
  String get tabFeed => isHindi ? 'मेरी फ़ीड' : 'My feed';
  String get tabVideo => isHindi ? 'वीडियो' : 'Video';
  String get tabDomestic => isHindi ? 'घरेलू' : 'Domestic';
  String get tabInternational => isHindi ? 'अंतरराष्ट्रीय' : 'International';
  String get tabNxtspot => isHindi ? 'नेक्स्टस्पॉट' : 'Nxtspot';
  String get navSearch => isHindi ? 'खोज' : 'Search';
  String get navHome => isHindi ? 'होम' : 'Home';
  String get navProfile => isHindi ? 'प्रोफ़ाइल' : 'Profile';
  String get searchHint =>
      isHindi ? 'क्रिकेट खबर खोजें' : 'Search cricket news';
  String get searchLabel => isHindi ? 'खोज' : 'Search';
  String get trending => isHindi ? 'चर्चित' : 'Trending';
  String get noResults =>
      isHindi ? 'कोई खबर नहीं मिली' : 'No stories match that search';
  String get noResultsBody => isHindi
      ? 'खिलाड़ी, टीम या सीरीज़ का नाम आज़माएँ।'
      : 'Try a player, team, or series name.';
  String get feedLoadError =>
      isHindi ? 'फ़ीड नहीं खुल सकी' : 'Couldn’t load the feed';
  String get feedLoadErrorBody => isHindi
      ? 'कनेक्शन जाँचें, फिर फिर से कोशिश करें।'
      : 'Check your connection, then try again.';
  String get tryAgain => isHindi ? 'फिर कोशिश करें' : 'Try again';
  String get noStories => isHindi ? 'अभी कोई खबर नहीं' : 'No stories yet';
  String get noStoriesBody => isHindi
      ? 'छपते ही कार्ड यहाँ दिखेंगे।'
      : 'New cards appear here as soon as they publish.';
  String get newPosts => isHindi ? 'नई खबरें' : 'New posts';
  String get offlineBanner => isHindi
      ? 'आप ऑफ़लाइन हैं। सहेजे कार्ड दिख रहे हैं।'
      : 'You’re offline. Showing saved cards.';
  String readMoreAt(String source) =>
      isHindi ? '$source पर पढ़ें' : 'Read more at $source';
  String get shareCard => isHindi ? 'कार्ड साझा करें' : 'Share this card';
  String get saveCard => isHindi ? 'सहेजें' : 'Save';
  String get savedCard => isHindi ? 'सहेजा गया' : 'Saved';
  String get showHindi => isHindi ? 'हिन्दी दिखाएँ' : 'Show Hindi';
  String get showEnglish => isHindi ? 'अंग्रेज़ी दिखाएँ' : 'Show English';
  String get playVideo => isHindi ? 'वीडियो चलाएँ' : 'Play video';
  String get welcomeTitle =>
      isHindi ? 'क्रिकेट, एक मिनट में' : 'Cricket, one minute at a time';
  String get welcomeBody => isHindi
      ? 'साठ शब्दों के कार्ड, छोटे वीडियो, और घरेलू क्रिकेट जो और कोई नहीं दिखाता।'
      : 'Sixty-word cards, short videos, and grassroots cricket nobody else reports.';
  String get continueWithPhone =>
      isHindi ? 'फ़ोन से जारी रखें' : 'Continue with phone';
  String get skipForNow => isHindi ? 'अभी छोड़ें' : 'Skip for now';
  String get phoneTitle => isHindi ? 'आपका फ़ोन नंबर' : 'Your phone number';
  String get phoneBody => isHindi
      ? 'एक बार का कोड भेजेंगे। बाद में साइन इन कर सकते हैं।'
      : 'We’ll send a one-time code. You can skip and sign in later.';
  String get phoneLabel => isHindi ? 'मोबाइल नंबर' : 'Mobile number';
  String get phoneHint => isHindi ? '10 अंकों का नंबर' : '10-digit number';
  String get sendCode => isHindi ? 'कोड भेजें' : 'Send code';
  String get otpTitle => isHindi ? 'कोड लिखें' : 'Enter the code';
  String get otpBody => isHindi
      ? 'एसएमएस से लिखें या पेस्ट करें। कोड कुछ मिनट में समाप्त हो जाता है।'
      : 'Typed from SMS, or paste it. The code expires in a few minutes.';
  String get otpLabel => isHindi ? 'एक बार का कोड' : 'One-time code';
  String get verifyCode => isHindi ? 'पुष्टि करें' : 'Verify';
  String get profileTitle => isHindi ? 'प्रोफ़ाइल' : 'Profile';
  String get signInCta =>
      isHindi ? 'फ़ोन नंबर से साइन इन करें' : 'Sign in with your phone number';
  String get signedInAs => isHindi ? 'साइन इन हैं' : 'Signed in';
  String get language => isHindi ? 'भाषा' : 'Language';
  String get english => isHindi ? 'अंग्रेज़ी' : 'English';
  String get hindi => isHindi ? 'हिन्दी' : 'Hindi';
  String get notifications => isHindi ? 'सूचनाएँ' : 'Notifications';
  String get nightMode => isHindi ? 'रात्रि मोड' : 'Night mode';
  String get textSize => isHindi ? 'अक्षर आकार' : 'Text size';
  String get autoplay => isHindi ? 'वीडियो अपने आप चलाएँ' : 'Autoplay videos';
  String get savedStories => isHindi ? 'सहेजी खबरें' : 'Saved stories';
  String get noSaved => isHindi ? 'कोई सहेजी खबर नहीं' : 'No saved stories';
  String get noSavedBody => isHindi
      ? 'कार्ड पर सहेजें दबाएँ।'
      : 'Tap save on a card to keep it here.';
  String get signOut => isHindi ? 'साइन आउट' : 'Sign out';
  String get deleteAccount => isHindi ? 'खाता हटाएँ' : 'Delete account';
  String get deleteAccountBody => isHindi
      ? 'हर डिवाइस से साइन आउट हो जाएँगे। डेटा 30 दिन बाद हट जाएगा।'
      : 'This signs you out everywhere. We’ll remove your data after 30 days.';
  String get cancel => isHindi ? 'रद्द करें' : 'Cancel';
  String get delete => isHindi ? 'हटाएँ' : 'Delete';
  String get systemTheme => isHindi ? 'सिस्टम' : 'System';
  String get lightTheme => isHindi ? 'हल्की' : 'Light';
  String get darkTheme => isHindi ? 'गहरी' : 'Dark';
  String get textSizeS => isHindi ? 'छोटा' : 'Small';
  String get textSizeM => isHindi ? 'सामान्य' : 'Default';
  String get textSizeL => isHindi ? 'बड़ा' : 'Large';
  String get wrongOtp => isHindi
      ? 'कोड गलत है। एसएमएस देखकर फिर लिखें।'
      : 'That code is wrong. Check the SMS and try again.';
  String get phoneInvalid => isHindi
      ? '10 अंकों का भारतीय मोबाइल नंबर लिखें।'
      : 'Enter a 10-digit Indian mobile number.';
  String get tooManyAttempts => isHindi
      ? 'बहुत कोशिशें हो गईं। आधा मिनट बाद आज़माएँ।'
      : 'Too many tries. Wait half a minute and try again.';
  String get authOffline => isHindi
      ? 'आप ऑफ़लाइन हैं। जुड़कर कोड फिर भेजें।'
      : 'You’re offline. Connect and send the code again.';
  String get setupTitle =>
      isHindi ? 'आपको क्या कहें?' : 'What should we call you?';
  String get setupBody => isHindi
      ? 'नाम वैकल्पिक है। बाद में प्रोफ़ाइल में जोड़ सकते हैं।'
      : 'A name is optional. You can add it later in profile.';
  String get nameLabel => isHindi ? 'नाम' : 'Name';
  String get saveAndContinue =>
      isHindi ? 'सहेजें और आगे बढ़ें' : 'Save and continue';
  String get openSource => isHindi ? 'मूल खबर खोलें' : 'Open original story';
}
