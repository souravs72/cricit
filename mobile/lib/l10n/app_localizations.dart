import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CRICIT'**
  String get appName;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'My feed'**
  String get tabFeed;

  /// No description provided for @tabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get tabVideo;

  /// No description provided for @tabDomestic.
  ///
  /// In en, this message translates to:
  /// **'Domestic'**
  String get tabDomestic;

  /// No description provided for @tabInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get tabInternational;

  /// No description provided for @tabNxtspot.
  ///
  /// In en, this message translates to:
  /// **'Nxtspot'**
  String get tabNxtspot;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cricket news'**
  String get searchHint;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No stories match that search'**
  String get noResults;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a player, team, or series name.'**
  String get noResultsBody;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the feed'**
  String get feedLoadError;

  /// No description provided for @feedLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get feedLoadErrorBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noStories.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get noStories;

  /// No description provided for @noStoriesBody.
  ///
  /// In en, this message translates to:
  /// **'New cards appear here as soon as they publish.'**
  String get noStoriesBody;

  /// No description provided for @newPosts.
  ///
  /// In en, this message translates to:
  /// **'New posts'**
  String get newPosts;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Showing saved cards.'**
  String get offlineBanner;

  /// No description provided for @readMoreAt.
  ///
  /// In en, this message translates to:
  /// **'Read more at {source}'**
  String readMoreAt(String source);

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share this card'**
  String get shareCard;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveCard;

  /// No description provided for @savedCard.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedCard;

  /// No description provided for @showHindi.
  ///
  /// In en, this message translates to:
  /// **'Show Hindi'**
  String get showHindi;

  /// No description provided for @showEnglish.
  ///
  /// In en, this message translates to:
  /// **'Show English'**
  String get showEnglish;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cricket, one minute at a time'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Sixty-word cards, short videos, and grassroots cricket nobody else reports.'**
  String get welcomeBody;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get phoneTitle;

  /// No description provided for @phoneBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a one-time code. You can skip and sign in later.'**
  String get phoneBody;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit number'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpBody.
  ///
  /// In en, this message translates to:
  /// **'Typed from SMS, or paste it. The code expires in a few minutes.'**
  String get otpBody;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get otpLabel;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number'**
  String get signInCta;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInAs;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @nightMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get nightMode;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay videos'**
  String get autoplay;

  /// No description provided for @savedStories.
  ///
  /// In en, this message translates to:
  /// **'Saved stories'**
  String get savedStories;

  /// No description provided for @noSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved stories'**
  String get noSaved;

  /// No description provided for @noSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Tap save on a card to keep it here.'**
  String get noSavedBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This signs you out everywhere. We’ll remove your data after 30 days.'**
  String get deleteAccountBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @textSizeS.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSizeS;

  /// No description provided for @textSizeM.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textSizeM;

  /// No description provided for @textSizeL.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeL;

  /// No description provided for @wrongOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong. Check the SMS and try again.'**
  String get wrongOtp;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit Indian mobile number.'**
  String get phoneInvalid;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait half a minute and try again.'**
  String get tooManyAttempts;

  /// No description provided for @authOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect and send the code again.'**
  String get authOffline;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'A name is optional. You can add it later in profile.'**
  String get setupBody;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open original story'**
  String get openSource;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
