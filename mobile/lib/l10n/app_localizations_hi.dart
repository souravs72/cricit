// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'क्रिकिट';

  @override
  String get tabFeed => 'मेरी फ़ीड';

  @override
  String get tabVideo => 'वीडियो';

  @override
  String get tabDomestic => 'घरेलू';

  @override
  String get tabInternational => 'अंतरराष्ट्रीय';

  @override
  String get tabNxtspot => 'नेक्स्टस्पॉट';

  @override
  String get navSearch => 'खोज';

  @override
  String get navHome => 'होम';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get searchHint => 'क्रिकेट खबर खोजें';

  @override
  String get searchLabel => 'खोज';

  @override
  String get trending => 'चर्चित';

  @override
  String get noResults => 'कोई खबर नहीं मिली';

  @override
  String get noResultsBody => 'खिलाड़ी, टीम या सीरीज़ का नाम आज़माएँ।';

  @override
  String get feedLoadError => 'फ़ीड नहीं खुल सकी';

  @override
  String get feedLoadErrorBody => 'कनेक्शन जाँचें, फिर फिर से कोशिश करें।';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get noStories => 'अभी कोई खबर नहीं';

  @override
  String get noStoriesBody => 'छपते ही कार्ड यहाँ दिखेंगे।';

  @override
  String get newPosts => 'नई खबरें';

  @override
  String get offlineBanner => 'आप ऑफ़लाइन हैं। सहेजे कार्ड दिख रहे हैं।';

  @override
  String readMoreAt(String source) {
    return '$source पर पढ़ें';
  }

  @override
  String get shareCard => 'कार्ड साझा करें';

  @override
  String get saveCard => 'सहेजें';

  @override
  String get savedCard => 'सहेजा गया';

  @override
  String get showHindi => 'हिन्दी दिखाएँ';

  @override
  String get showEnglish => 'अंग्रेज़ी दिखाएँ';

  @override
  String get playVideo => 'वीडियो चलाएँ';

  @override
  String get welcomeTitle => 'क्रिकेट, एक मिनट में';

  @override
  String get welcomeBody =>
      'साठ शब्दों के कार्ड, छोटे वीडियो, और घरेलू क्रिकेट जो और कोई नहीं दिखाता।';

  @override
  String get continueWithPhone => 'फ़ोन से जारी रखें';

  @override
  String get skipForNow => 'अभी छोड़ें';

  @override
  String get phoneTitle => 'आपका फ़ोन नंबर';

  @override
  String get phoneBody => 'एक बार का कोड भेजेंगे। बाद में साइन इन कर सकते हैं।';

  @override
  String get phoneLabel => 'मोबाइल नंबर';

  @override
  String get phoneHint => '10 अंकों का नंबर';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get otpTitle => 'कोड लिखें';

  @override
  String get otpBody =>
      'एसएमएस से लिखें या पेस्ट करें। कोड कुछ मिनट में समाप्त हो जाता है।';

  @override
  String get otpLabel => 'एक बार का कोड';

  @override
  String get verifyCode => 'पुष्टि करें';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get signInCta => 'फ़ोन नंबर से साइन इन करें';

  @override
  String get signedInAs => 'साइन इन हैं';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get nightMode => 'रात्रि मोड';

  @override
  String get textSize => 'अक्षर आकार';

  @override
  String get autoplay => 'वीडियो अपने आप चलाएँ';

  @override
  String get savedStories => 'सहेजी खबरें';

  @override
  String get noSaved => 'कोई सहेजी खबर नहीं';

  @override
  String get noSavedBody => 'कार्ड पर सहेजें दबाएँ।';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountBody =>
      'हर डिवाइस से साइन आउट हो जाएँगे। डेटा 30 दिन बाद हट जाएगा।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get systemTheme => 'सिस्टम';

  @override
  String get lightTheme => 'हल्की';

  @override
  String get darkTheme => 'गहरी';

  @override
  String get textSizeS => 'छोटा';

  @override
  String get textSizeM => 'सामान्य';

  @override
  String get textSizeL => 'बड़ा';

  @override
  String get wrongOtp => 'कोड गलत है। एसएमएस देखकर फिर लिखें।';

  @override
  String get phoneInvalid => '10 अंकों का भारतीय मोबाइल नंबर लिखें।';

  @override
  String get tooManyAttempts => 'बहुत कोशिशें हो गईं। आधा मिनट बाद आज़माएँ।';

  @override
  String get authOffline => 'आप ऑफ़लाइन हैं। जुड़कर कोड फिर भेजें।';

  @override
  String get setupTitle => 'आपको क्या कहें?';

  @override
  String get setupBody =>
      'नाम वैकल्पिक है। बाद में प्रोफ़ाइल में जोड़ सकते हैं।';

  @override
  String get nameLabel => 'नाम';

  @override
  String get saveAndContinue => 'सहेजें और आगे बढ़ें';

  @override
  String get openSource => 'मूल खबर खोलें';
}
