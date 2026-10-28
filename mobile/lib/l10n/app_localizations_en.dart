// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CRICIT';

  @override
  String get tabFeed => 'My feed';

  @override
  String get tabVideo => 'Video';

  @override
  String get tabDomestic => 'Domestic';

  @override
  String get tabInternational => 'International';

  @override
  String get tabNxtspot => 'Nxtspot';

  @override
  String get navSearch => 'Search';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchHint => 'Search cricket news';

  @override
  String get searchLabel => 'Search';

  @override
  String get trending => 'Trending';

  @override
  String get noResults => 'No stories match that search';

  @override
  String get noResultsBody => 'Try a player, team, or series name.';

  @override
  String get feedLoadError => 'Couldn’t load the feed';

  @override
  String get feedLoadErrorBody => 'Check your connection, then try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noStories => 'No stories yet';

  @override
  String get noStoriesBody => 'New cards appear here as soon as they publish.';

  @override
  String get newPosts => 'New posts';

  @override
  String get offlineBanner => 'You’re offline. Showing saved cards.';

  @override
  String readMoreAt(String source) {
    return 'Read more at $source';
  }

  @override
  String get shareCard => 'Share this card';

  @override
  String get saveCard => 'Save';

  @override
  String get savedCard => 'Saved';

  @override
  String get showHindi => 'Show Hindi';

  @override
  String get showEnglish => 'Show English';

  @override
  String get playVideo => 'Play video';

  @override
  String get welcomeTitle => 'Cricket, one minute at a time';

  @override
  String get welcomeBody =>
      'Sixty-word cards, short videos, and grassroots cricket nobody else reports.';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneBody =>
      'We’ll send a one-time code. You can skip and sign in later.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '10-digit number';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String get otpBody =>
      'Typed from SMS, or paste it. The code expires in a few minutes.';

  @override
  String get otpLabel => 'One-time code';

  @override
  String get verifyCode => 'Verify';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signInCta => 'Sign in with your phone number';

  @override
  String get signedInAs => 'Signed in';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get notifications => 'Notifications';

  @override
  String get nightMode => 'Night mode';

  @override
  String get textSize => 'Text size';

  @override
  String get autoplay => 'Autoplay videos';

  @override
  String get savedStories => 'Saved stories';

  @override
  String get noSaved => 'No saved stories';

  @override
  String get noSavedBody => 'Tap save on a card to keep it here.';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This signs you out everywhere. We’ll remove your data after 30 days.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get textSizeS => 'Small';

  @override
  String get textSizeM => 'Default';

  @override
  String get textSizeL => 'Large';

  @override
  String get wrongOtp => 'That code is wrong. Check the SMS and try again.';

  @override
  String get phoneInvalid => 'Enter a 10-digit Indian mobile number.';

  @override
  String get tooManyAttempts =>
      'Too many tries. Wait half a minute and try again.';

  @override
  String get authOffline => 'You’re offline. Connect and send the code again.';

  @override
  String get setupTitle => 'What should we call you?';

  @override
  String get setupBody =>
      'A name is optional. You can add it later in profile.';

  @override
  String get nameLabel => 'Name';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get openSource => 'Open original story';
}
