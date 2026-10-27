import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('tr'),
  ];

  /// No description provided for @tabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get tabAi;

  /// No description provided for @tabBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get tabBasic;

  /// No description provided for @photoTranslationTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Translation'**
  String get photoTranslationTitle;

  /// No description provided for @photoTranslationUpsell.
  ///
  /// In en, this message translates to:
  /// **'Translating text in photos is available on the Standard and Premium plans.'**
  String get photoTranslationUpsell;

  /// No description provided for @chooseTargetFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a target language first.'**
  String get chooseTargetFirst;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Translate it. Save it. Learn it.'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Translate with AI, save the words you meet and learn them with spaced repetition.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signInAndSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in and Sync'**
  String get signInAndSync;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Login failed'**
  String get googleLoginFailed;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the '**
  String get legalPrefix;

  /// No description provided for @legalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalAnd;

  /// No description provided for @legalSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legalSuffix;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signInToSyncProgress.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your progress'**
  String get signInToSyncProgress;

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaq;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account, decks, cards, favorites and history are deleted on all devices. This cannot be undone.\n\nAn App Store subscription is not cancelled by this; manage it in Settings > your name > Subscriptions.'**
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

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @syncAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Sync your data across devices'**
  String get syncAcrossDevices;

  /// No description provided for @syncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get syncFailedRetry;

  /// No description provided for @syncFailedConnection.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please check your connection and try again.'**
  String get syncFailedConnection;

  /// No description provided for @synchronize.
  ///
  /// In en, this message translates to:
  /// **'Synchronize'**
  String get synchronize;

  /// No description provided for @syncSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your decks, favorites and history across all your devices.'**
  String get syncSignInBody;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How many translations can I make?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Free: 10 AI translations a day. Standard and Premium: unlimited. Basic translation runs on your phone and is always free.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'Do my photos leave my phone?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'No. The text is read on your phone and only that text is sent to be translated.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'What is Live translation?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Premium translates speech as it is spoken, with captions: 60 minutes a month (5 minutes in the free trial). The minutes renew every month.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How does Study with AI work?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'Standard and Premium: AI writes a new sentence for each of 10 to 30 words from a deck, and you fill in the blank. Each word gets two tries. A new session can start 3 hours after the last one began.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I sync my decks between devices?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Sign in on the Profile page, then tap Sync Now.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In en, this message translates to:
  /// **'Can I translate without internet?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In en, this message translates to:
  /// **'Yes, on the Basic page. Each language downloads once (about 30 MB) and then works offline.'**
  String get faqA6;

  /// No description provided for @faqQ7.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get faqQ7;

  /// No description provided for @faqA7.
  ///
  /// In en, this message translates to:
  /// **'On your iPhone: Settings > your name > Subscriptions. Deleting the app or your account does not cancel it.'**
  String get faqA7;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @decksTitle.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get decksTitle;

  /// No description provided for @newDeck.
  ///
  /// In en, this message translates to:
  /// **'New Deck'**
  String get newDeck;

  /// No description provided for @createFirstDeck.
  ///
  /// In en, this message translates to:
  /// **'Create your first deck to start learning!'**
  String get createFirstDeck;

  /// No description provided for @deckName.
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get deckName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cardCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card} other{{count} cards}}'**
  String cardCount(int count);

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @browseCards.
  ///
  /// In en, this message translates to:
  /// **'Browse Cards'**
  String get browseCards;

  /// No description provided for @deckSettings.
  ///
  /// In en, this message translates to:
  /// **'Deck Settings'**
  String get deckSettings;

  /// No description provided for @deleteDeck.
  ///
  /// In en, this message translates to:
  /// **'Delete Deck'**
  String get deleteDeck;

  /// No description provided for @deleteDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Deck?'**
  String get deleteDeckTitle;

  /// No description provided for @deleteDeckBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its cards?'**
  String deleteDeckBody(String name);

  /// No description provided for @deleteDeckEndsSession.
  ///
  /// In en, this message translates to:
  /// **' Its Study with AI session ends too.'**
  String get deleteDeckEndsSession;

  /// No description provided for @dailyNewLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily New Cards Limit'**
  String get dailyNewLimit;

  /// No description provided for @dailyReviewLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Reviews Limit'**
  String get dailyReviewLimit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 card?} other{Delete {count} cards?}}'**
  String deleteCardsTitle(int count);

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @noCardsYet.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get noCardsYet;

  /// No description provided for @featTranslations.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI translations'**
  String get featTranslations;

  /// No description provided for @featTranslationsDetail.
  ///
  /// In en, this message translates to:
  /// **'Standard, formal and slang versions of every sentence.'**
  String get featTranslationsDetail;

  /// No description provided for @featPhoto.
  ///
  /// In en, this message translates to:
  /// **'AI photo translation'**
  String get featPhoto;

  /// No description provided for @featPhotoDetail.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at signs, menus and documents.'**
  String get featPhotoDetail;

  /// No description provided for @featPhotoWords.
  ///
  /// In en, this message translates to:
  /// **'Words from photos to your decks'**
  String get featPhotoWords;

  /// No description provided for @featPhotoWordsDetail.
  ///
  /// In en, this message translates to:
  /// **'AI picks out the useful words; add them in one tap.'**
  String get featPhotoWordsDetail;

  /// No description provided for @featDecks.
  ///
  /// In en, this message translates to:
  /// **'Unlimited decks and cards'**
  String get featDecks;

  /// No description provided for @featDecksDetail.
  ///
  /// In en, this message translates to:
  /// **'Save every word you want to learn and study it later.'**
  String get featDecksDetail;

  /// No description provided for @featLive.
  ///
  /// In en, this message translates to:
  /// **'AI Live translation'**
  String get featLive;

  /// No description provided for @featLiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Speech translated as it is spoken, keeping tone and emphasis, with live captions. 60 min/month'**
  String get featLiveDetail;

  /// No description provided for @studyWithAi.
  ///
  /// In en, this message translates to:
  /// **'Study with AI'**
  String get studyWithAi;

  /// No description provided for @featStudyDetail.
  ///
  /// In en, this message translates to:
  /// **'AI writes new sentences with your saved words; you fill in the blanks.'**
  String get featStudyDetail;

  /// No description provided for @plansHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn every translation\ninto a lesson.'**
  String get plansHeadline;

  /// No description provided for @plansTrialLine.
  ///
  /// In en, this message translates to:
  /// **'Try any plan free for {days} days. Cancel anytime.'**
  String plansTrialLine(int days);

  /// No description provided for @yourPlanLine.
  ///
  /// In en, this message translates to:
  /// **'Your plan: {tier}'**
  String yourPlanLine(String tier);

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @liveTrialNote.
  ///
  /// In en, this message translates to:
  /// **'* The Premium trial includes 5 minutes of Live translation.'**
  String get liveTrialNote;

  /// No description provided for @trialTerms.
  ///
  /// In en, this message translates to:
  /// **'After the {days}-day free trial, the subscription starts automatically unless you cancel at least 24 hours before the trial ends. One free trial per Apple ID. '**
  String trialTerms(int days);

  /// No description provided for @renewalTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically each month at the price shown unless you cancel at least 24 hours before the current period ends. Payment is charged to your Apple ID. You can manage or cancel your subscription in your App Store account settings.'**
  String get renewalTerms;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @perMonthCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'{price}/month · cancel anytime'**
  String perMonthCancelAnytime(String price);

  /// No description provided for @startTrial.
  ///
  /// In en, this message translates to:
  /// **'Start {days}-day free trial'**
  String startTrial(int days);

  /// No description provided for @thenPerMonth.
  ///
  /// In en, this message translates to:
  /// **'then {price}/month · cancel anytime'**
  String thenPerMonth(String price);

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlan;

  /// No description provided for @daysFree.
  ///
  /// In en, this message translates to:
  /// **'{days} days free'**
  String daysFree(int days);

  /// No description provided for @planSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {price} per month'**
  String planSemantics(String name, String price);

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String pricePerMonth(String price);

  /// No description provided for @trialToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get trialToday;

  /// No description provided for @trialTodayDetail.
  ///
  /// In en, this message translates to:
  /// **'Full access to {name} starts.'**
  String trialTodayDetail(String name);

  /// No description provided for @trialDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String trialDay(int day);

  /// No description provided for @trialDay14Detail.
  ///
  /// In en, this message translates to:
  /// **'Your subscription starts at {price}/month unless you cancel.'**
  String trialDay14Detail(String price);

  /// No description provided for @howTrialWorks.
  ///
  /// In en, this message translates to:
  /// **'How the free trial works'**
  String get howTrialWorks;

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @tierStandardTrial.
  ///
  /// In en, this message translates to:
  /// **'Standard (free trial)'**
  String get tierStandardTrial;

  /// No description provided for @tierPremiumTrial.
  ///
  /// In en, this message translates to:
  /// **'Premium (free trial)'**
  String get tierPremiumTrial;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get autoDetect;

  /// No description provided for @liveConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get liveConnecting;

  /// No description provided for @liveListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get liveListening;

  /// No description provided for @liveStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get liveStopped;

  /// No description provided for @liveReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get liveReady;

  /// No description provided for @muteVoice.
  ///
  /// In en, this message translates to:
  /// **'Mute translated voice'**
  String get muteVoice;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String minutesLeft(int minutes);

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String secondsLeft(int seconds);

  /// No description provided for @trialTime.
  ///
  /// In en, this message translates to:
  /// **'Trial · {time}'**
  String trialTime(String time);

  /// No description provided for @startSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Start speaking'**
  String get startSpeaking;

  /// No description provided for @liveTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Live Translation'**
  String get liveTitle;

  /// No description provided for @liveActiveHint.
  ///
  /// In en, this message translates to:
  /// **'The translation appears here as the speaker talks.'**
  String get liveActiveHint;

  /// No description provided for @liveIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic and let someone speak. AI translates as they talk, keeping their tone and emphasis, and writes it here too.'**
  String get liveIdleHint;

  /// No description provided for @liveTrialIncludes.
  ///
  /// In en, this message translates to:
  /// **'Your trial includes {minutes} minutes of Live. Premium includes 60 minutes every month.'**
  String liveTrialIncludes(int minutes);

  /// No description provided for @micOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in Settings > Privacy > Microphone.'**
  String get micOff;

  /// No description provided for @trialMinutesUsedShort.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your trial minutes. Premium includes 60 minutes of Live translation every month.'**
  String get trialMinutesUsedShort;

  /// No description provided for @liveMonthUsed.
  ///
  /// In en, this message translates to:
  /// **'You have used this month\'s live translation time.'**
  String get liveMonthUsed;

  /// No description provided for @liveMonthUsedResets.
  ///
  /// In en, this message translates to:
  /// **'You have used this month\'s live translation time. It resets on {day}/{month}.'**
  String liveMonthUsedResets(int day, int month);

  /// No description provided for @liveStoppedRetry.
  ///
  /// In en, this message translates to:
  /// **'Live translation stopped. Tap the mic to try again.'**
  String get liveStoppedRetry;

  /// No description provided for @trialMinutesUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial minutes used'**
  String get trialMinutesUsedTitle;

  /// No description provided for @trialMinutesUsedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your free trial minutes of Live translation. Premium includes 60 minutes every month once your subscription starts.'**
  String get trialMinutesUsedBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @couldNotEndSession.
  ///
  /// In en, this message translates to:
  /// **'Could not end the session. Check your connection.'**
  String get couldNotEndSession;

  /// No description provided for @deckNotFoundEnd.
  ///
  /// In en, this message translates to:
  /// **'The deck wasn\'t found. You can end the session instead.'**
  String get deckNotFoundEnd;

  /// No description provided for @continueProgress.
  ///
  /// In en, this message translates to:
  /// **'Continue · {done}/{total}'**
  String continueProgress(int done, int total);

  /// No description provided for @addMoreWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 more word} other{Add {count} more words}}'**
  String addMoreWords(int count);

  /// No description provided for @needsTenWords.
  ///
  /// In en, this message translates to:
  /// **'Study with AI needs a deck with at least 10 words.'**
  String get needsTenWords;

  /// No description provided for @pickDeck.
  ///
  /// In en, this message translates to:
  /// **'Pick a deck. Each session practises 10 of its words.'**
  String get pickDeck;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// No description provided for @deckNotOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Deck not on this phone'**
  String get deckNotOnPhone;

  /// No description provided for @missingDeckIntro.
  ///
  /// In en, this message translates to:
  /// **'This session is from \"{deck}\", which isn\'t on this phone. '**
  String missingDeckIntro(String deck);

  /// No description provided for @missingDeckSync.
  ///
  /// In en, this message translates to:
  /// **'Sync to bring it back, or end the session. '**
  String get missingDeckSync;

  /// No description provided for @missingDeckEndNote.
  ///
  /// In en, this message translates to:
  /// **'Ending it starts the usual break before the next session.'**
  String get missingDeckEndNote;

  /// No description provided for @syncNowLower.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowLower;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @finishSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get finishSessionTitle;

  /// No description provided for @finishSessionBody.
  ///
  /// In en, this message translates to:
  /// **'The words you answered are saved. The next session opens {hours} hours after this one began.'**
  String finishSessionBody(int hours);

  /// No description provided for @nextSession.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get nextSession;

  /// No description provided for @readyNow.
  ///
  /// In en, this message translates to:
  /// **'Ready now'**
  String get readyNow;

  /// No description provided for @breakNote.
  ///
  /// In en, this message translates to:
  /// **'Words stick better with a break between sessions. Meanwhile you can review them with flashcards.'**
  String get breakNote;

  /// No description provided for @reviewWithFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Review {deck} with flashcards'**
  String reviewWithFlashcards(String deck);

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @firstTryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} first try'**
  String firstTryCount(int count);

  /// No description provided for @secondTryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} on the second try'**
  String secondTryCount(int count);

  /// No description provided for @missedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missed'**
  String missedCount(int count);

  /// No description provided for @nextSessionIn.
  ///
  /// In en, this message translates to:
  /// **'Next session in '**
  String get nextSessionIn;

  /// No description provided for @reviewWithFlashcardsShort.
  ///
  /// In en, this message translates to:
  /// **'Review with flashcards'**
  String get reviewWithFlashcardsShort;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @gettingWordsReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your words ready'**
  String get gettingWordsReady;

  /// No description provided for @studyNeedsPlan.
  ///
  /// In en, this message translates to:
  /// **'Study with AI is available on the Standard and Premium plans.'**
  String get studyNeedsPlan;

  /// No description provided for @nextSessionStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Your next session starts in {time}.'**
  String nextSessionStartsIn(String time);

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get seePlans;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get noInternet;

  /// No description provided for @tooManyMessages.
  ///
  /// In en, this message translates to:
  /// **'Too many messages at once. Wait a moment and try again.'**
  String get tooManyMessages;

  /// No description provided for @aiBusy.
  ///
  /// In en, this message translates to:
  /// **'The AI is busy right now. Try again in a few seconds.'**
  String get aiBusy;

  /// No description provided for @studyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Study with AI is unavailable right now. Try again later.'**
  String get studyUnavailable;

  /// No description provided for @replyTooLong.
  ///
  /// In en, this message translates to:
  /// **'The reply took too long. Try again.'**
  String get replyTooLong;

  /// No description provided for @couldNotGetReply.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a reply. Try again.'**
  String get couldNotGetReply;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @typeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type the missing word'**
  String get typeAnswer;

  /// No description provided for @errConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get errConnectionTitle;

  /// No description provided for @errConnectionMsg.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errConnectionMsg;

  /// No description provided for @errUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Unavailable'**
  String get errUnavailableTitle;

  /// No description provided for @errUnavailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Translation is temporarily unavailable. Please try again later.'**
  String get errUnavailableMsg;

  /// No description provided for @errBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Is Busy'**
  String get errBusyTitle;

  /// No description provided for @errBusyMsg.
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Try again in a few seconds.'**
  String get errBusyMsg;

  /// No description provided for @errTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Took Too Long'**
  String get errTimeoutTitle;

  /// No description provided for @errTimeoutMsg.
  ///
  /// In en, this message translates to:
  /// **'The translation took too long. Please try again.'**
  String get errTimeoutMsg;

  /// No description provided for @errBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t Translate This'**
  String get errBlockedTitle;

  /// No description provided for @errBlockedMsg.
  ///
  /// In en, this message translates to:
  /// **'This text couldn\'t be translated.'**
  String get errBlockedMsg;

  /// No description provided for @errFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get errFailedTitle;

  /// No description provided for @errFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Translation could not be completed. Please try again.'**
  String get errFailedMsg;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @dailyLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit Reached'**
  String get dailyLimitTitle;

  /// No description provided for @dailyLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 10 free AI translations for today. You can keep using offline translation, or upgrade for unlimited AI translations.'**
  String get dailyLimitBody;

  /// No description provided for @slowDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow Down'**
  String get slowDownTitle;

  /// No description provided for @slowDownBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re sending requests too fast. Please wait a few seconds and try again.'**
  String get slowDownBody;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @deckLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Deck Limit Reached'**
  String get deckLimitTitle;

  /// No description provided for @deckLimitBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The free plan includes 1 deck. Upgrade for unlimited decks and cards.} other{The free plan includes {count} decks. Upgrade for unlimited decks and cards.}}'**
  String deckLimitBody(int count);

  /// No description provided for @cardLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Limit Reached'**
  String get cardLimitTitle;

  /// No description provided for @cardLimitBody.
  ///
  /// In en, this message translates to:
  /// **'The free plan allows up to {count} cards per deck. Upgrade for unlimited cards.'**
  String cardLimitBody(int count);

  /// No description provided for @backToDecks.
  ///
  /// In en, this message translates to:
  /// **'Back to Decks'**
  String get backToDecks;

  /// No description provided for @sessionFinished.
  ///
  /// In en, this message translates to:
  /// **'Session Finished!'**
  String get sessionFinished;

  /// No description provided for @noCardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cards available'**
  String get noCardsAvailable;

  /// No description provided for @cardProgress.
  ///
  /// In en, this message translates to:
  /// **'Card {index} / {total}'**
  String cardProgress(int index, int total);

  /// No description provided for @rateAgain.
  ///
  /// In en, this message translates to:
  /// **'🔴 ← AGAIN'**
  String get rateAgain;

  /// No description provided for @rateGood.
  ///
  /// In en, this message translates to:
  /// **'🟢 GOOD →'**
  String get rateGood;

  /// No description provided for @rateEasy.
  ///
  /// In en, this message translates to:
  /// **'🔵 ↑ EASY'**
  String get rateEasy;

  /// No description provided for @rateHard.
  ///
  /// In en, this message translates to:
  /// **'🟠 ↓ HARD'**
  String get rateHard;

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'SHOW ANSWER'**
  String get showAnswer;

  /// No description provided for @swipeToRate.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Rate'**
  String get swipeToRate;

  /// No description provided for @rateLegend.
  ///
  /// In en, this message translates to:
  /// **'🔴 Again  •  🟠 Hard  •  🟢 Good  •  🔵 Easy'**
  String get rateLegend;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all history?'**
  String get clearHistoryConfirm;

  /// No description provided for @translationHint.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationHint;

  /// No description provided for @toneStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get toneStandard;

  /// No description provided for @toneFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get toneFormal;

  /// No description provided for @toneSlang.
  ///
  /// In en, this message translates to:
  /// **'Slang'**
  String get toneSlang;

  /// No description provided for @toneLabel.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get toneLabel;

  /// No description provided for @saveToDeck.
  ///
  /// In en, this message translates to:
  /// **'Save to Deck'**
  String get saveToDeck;

  /// No description provided for @noDecksFound.
  ///
  /// In en, this message translates to:
  /// **'No decks found.\nCreate a deck first.'**
  String get noDecksFound;

  /// No description provided for @saveFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Save Flashcard'**
  String get saveFlashcard;

  /// No description provided for @saveWordToDeck.
  ///
  /// In en, this message translates to:
  /// **'Save word to {deck}?'**
  String saveWordToDeck(String deck);

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you use AI'**
  String get consentTitle;

  /// No description provided for @consentBody1.
  ///
  /// In en, this message translates to:
  /// **'AI translation, photo translation, Live and Study with AI send the text you enter, the text read from your photo, your voice in Live and your deck\'s words to Google Gemini to be processed.'**
  String get consentBody1;

  /// No description provided for @consentBody2.
  ///
  /// In en, this message translates to:
  /// **'Your photos never leave your phone. Basic translation works on your phone without this.'**
  String get consentBody2;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @cardFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get cardFront;

  /// No description provided for @cardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cardBack;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @restartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Required'**
  String get restartTitle;

  /// No description provided for @restartBody.
  ///
  /// In en, this message translates to:
  /// **'Please close and reopen the app to keep translating as a guest, or sign back in.'**
  String get restartBody;

  /// No description provided for @translateFrom.
  ///
  /// In en, this message translates to:
  /// **'Translate from: '**
  String get translateFrom;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFrench;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @langItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get langItalian;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJapanese;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get langChinese;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKorean;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @langPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get langPortuguese;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get langHindi;

  /// No description provided for @langUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get langUrdu;

  /// No description provided for @langPersian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get langPersian;

  /// No description provided for @langDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get langDutch;

  /// No description provided for @langSwedish.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get langSwedish;

  /// No description provided for @langNorwegian.
  ///
  /// In en, this message translates to:
  /// **'Norwegian'**
  String get langNorwegian;

  /// No description provided for @langDanish.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get langDanish;

  /// No description provided for @langFinnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get langFinnish;

  /// No description provided for @langPolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get langPolish;

  /// No description provided for @langGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get langGreek;

  /// No description provided for @langHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get langHebrew;

  /// No description provided for @langTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get langTurkish;

  /// No description provided for @recents.
  ///
  /// In en, this message translates to:
  /// **'RECENTS'**
  String get recents;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'ALL LANGUAGES'**
  String get allLanguages;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @couldNotTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not take the photo. Try again.'**
  String get couldNotTakePhoto;

  /// No description provided for @couldNotOpenPhotos.
  ///
  /// In en, this message translates to:
  /// **'Could not open your photos.'**
  String get couldNotOpenPhotos;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @copyTranslation.
  ///
  /// In en, this message translates to:
  /// **'Copy translation'**
  String get copyTranslation;

  /// No description provided for @copyOriginal.
  ///
  /// In en, this message translates to:
  /// **'Copy original text'**
  String get copyOriginal;

  /// No description provided for @translationCopied.
  ///
  /// In en, this message translates to:
  /// **'Translation copied'**
  String get translationCopied;

  /// No description provided for @originalCopied.
  ///
  /// In en, this message translates to:
  /// **'Original text copied'**
  String get originalCopied;

  /// No description provided for @tip1.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone flat over the text.'**
  String get tip1;

  /// No description provided for @tip2.
  ///
  /// In en, this message translates to:
  /// **'Good light helps; use the flash in the dark.'**
  String get tip2;

  /// No description provided for @tip3.
  ///
  /// In en, this message translates to:
  /// **'Tap the screen to focus.'**
  String get tip3;

  /// No description provided for @tip4.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom in on small text.'**
  String get tip4;

  /// No description provided for @tip5.
  ///
  /// In en, this message translates to:
  /// **'Press and hold a translation to select and copy it.'**
  String get tip5;

  /// No description provided for @tip6.
  ///
  /// In en, this message translates to:
  /// **'Swipe up the word list to add words to a deck.'**
  String get tip6;

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for better results'**
  String get tipsTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @swapLanguages.
  ///
  /// In en, this message translates to:
  /// **'Swap languages'**
  String get swapLanguages;

  /// No description provided for @cameraOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get cameraOffTitle;

  /// No description provided for @cameraOffBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access for Decklingo in Settings > Privacy > Camera, or pick a photo from your gallery.'**
  String get cameraOffBody;

  /// No description provided for @cameraUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailableTitle;

  /// No description provided for @cameraUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started on this device. You can still pick a photo from your gallery.'**
  String get cameraUnavailableBody;

  /// No description provided for @holdStraight.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone straight and parallel to the text for the best fit.'**
  String get holdStraight;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get flashOff;

  /// No description provided for @flashAuto.
  ///
  /// In en, this message translates to:
  /// **'Flash auto'**
  String get flashAuto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @linesTranslatedTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line translated to {language}} other{{count} lines translated to {language}}}'**
  String linesTranslatedTo(int count, String language);

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @noWordsFound.
  ///
  /// In en, this message translates to:
  /// **'No words to add were found in this photo.'**
  String get noWordsFound;

  /// No description provided for @addToDeck.
  ///
  /// In en, this message translates to:
  /// **'Add to deck'**
  String get addToDeck;

  /// No description provided for @readingText.
  ///
  /// In en, this message translates to:
  /// **'Reading text…'**
  String get readingText;

  /// No description provided for @translatingLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Translating 1 line…} other{Translating {count} lines…}}'**
  String translatingLines(int count);

  /// No description provided for @noTextFound.
  ///
  /// In en, this message translates to:
  /// **'No text found. Try a closer, sharper photo, or check the source language.'**
  String get noTextFound;

  /// No description provided for @couldNotOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo. Please retake it.'**
  String get couldNotOpenPhoto;

  /// No description provided for @unsupportedPhotoLanguage.
  ///
  /// In en, this message translates to:
  /// **'Text in {language} can\'t be read from photos yet. Choose another source language.'**
  String unsupportedPhotoLanguage(String language);

  /// No description provided for @unsupportedPhotoLanguageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Text in this language can\'t be read from photos yet. Choose another source language.'**
  String get unsupportedPhotoLanguageUnknown;

  /// No description provided for @couldNotReadText.
  ///
  /// In en, this message translates to:
  /// **'Could not read the text. Please try again.'**
  String get couldNotReadText;

  /// No description provided for @tooManyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Too many photo translations. Wait a few seconds and retry.'**
  String get tooManyPhotos;

  /// No description provided for @photoNeedsStandard.
  ///
  /// In en, this message translates to:
  /// **'Photo translation is available on the Standard plan.'**
  String get photoNeedsStandard;

  /// No description provided for @restartOrSignIn.
  ///
  /// In en, this message translates to:
  /// **'Restart the app or sign in to continue.'**
  String get restartOrSignIn;

  /// No description provided for @welcomeBackWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Welcome back, 1 word to go.} other{Welcome back, {count} words to go.}}'**
  String welcomeBackWords(int count);

  /// No description provided for @studyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Let\'s study {count} words from \"{deck}\". Type the missing word in each sentence.'**
  String studyGreeting(String deck, int count);

  /// No description provided for @studyCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get studyCorrect;

  /// No description provided for @studyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get studyTryAgain;

  /// No description provided for @studyAnswerWas.
  ///
  /// In en, this message translates to:
  /// **'The answer was \"{word}\".'**
  String studyAnswerWas(String word);

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered.'**
  String get authEmailInUse;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password too weak (min 6 chars).'**
  String get authWeakPassword;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get authNetwork;

  /// No description provided for @authInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input. Please check your details.'**
  String get authInvalidInput;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @failedLoadDecks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load decks'**
  String get failedLoadDecks;

  /// No description provided for @failedAddDeck.
  ///
  /// In en, this message translates to:
  /// **'Failed to add deck'**
  String get failedAddDeck;

  /// No description provided for @failedDeleteDeck.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete deck'**
  String get failedDeleteDeck;

  /// No description provided for @failedAddCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to add card'**
  String get failedAddCard;

  /// No description provided for @cardTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long for a card: the word can be up to {word} characters, the translation up to {translation}.'**
  String cardTooLong(int word, int translation);

  /// No description provided for @failedDeleteCards.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete cards'**
  String get failedDeleteCards;

  /// No description provided for @failedUpdateDeckSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update deck settings'**
  String get failedUpdateDeckSettings;

  /// No description provided for @failedUpdateDeckLimits.
  ///
  /// In en, this message translates to:
  /// **'Failed to update deck limits'**
  String get failedUpdateDeckLimits;

  /// No description provided for @failedLoadLimits.
  ///
  /// In en, this message translates to:
  /// **'Failed to load account limits'**
  String get failedLoadLimits;

  /// No description provided for @failedLoadFavorites.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites'**
  String get failedLoadFavorites;

  /// No description provided for @failedSaveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to save favorite'**
  String get failedSaveFavorite;

  /// No description provided for @failedDeleteFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete favorite'**
  String get failedDeleteFavorite;

  /// No description provided for @geminiNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get geminiNoInternet;

  /// No description provided for @dailyAiLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily AI limit reached. Try offline mode or upgrade for unlimited translations.'**
  String get dailyAiLimit;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests! Please wait a few seconds and try again.'**
  String get tooManyRequests;

  /// No description provided for @aiOverloaded.
  ///
  /// In en, this message translates to:
  /// **'AI servers are currently overloaded. Please wait a few seconds and try again.'**
  String get aiOverloaded;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {details}'**
  String errorOccurred(String details);

  /// No description provided for @failedLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get failedLoadHistory;

  /// No description provided for @failedSaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save history item'**
  String get failedSaveHistory;

  /// No description provided for @failedDeleteHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete history item'**
  String get failedDeleteHistory;

  /// No description provided for @failedClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear history'**
  String get failedClearHistory;

  /// No description provided for @failedDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to download model for {language}'**
  String failedDownloadModel(String language);

  /// No description provided for @failedInitTranslator.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize translator'**
  String get failedInitTranslator;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get translationFailed;

  /// No description provided for @failedInitStudy.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize study session'**
  String get failedInitStudy;

  /// No description provided for @failedSaveRating.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rating'**
  String get failedSaveRating;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @plansLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the plans. Check your connection.'**
  String get plansLoadFailed;

  /// No description provided for @signInToSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Sign in first so your plan stays with your account.'**
  String get signInToSubscribe;

  /// No description provided for @purchaseDone.
  ///
  /// In en, this message translates to:
  /// **'Your plan is active.'**
  String get purchaseDone;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Try again.'**
  String get purchaseFailed;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Your purchases are restored.'**
  String get restoreDone;

  /// No description provided for @restoreNothing.
  ///
  /// In en, this message translates to:
  /// **'No active subscription was found for this Apple ID.'**
  String get restoreNothing;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore purchases. Try again.'**
  String get restoreFailed;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCard;

  /// No description provided for @failedEditCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the card'**
  String get failedEditCard;

  /// No description provided for @noCardsAdded.
  ///
  /// In en, this message translates to:
  /// **'No cards added yet'**
  String get noCardsAdded;

  /// No description provided for @exampleSentences.
  ///
  /// In en, this message translates to:
  /// **'Example sentences'**
  String get exampleSentences;

  /// No description provided for @switchToStandard.
  ///
  /// In en, this message translates to:
  /// **'Switch to Standard'**
  String get switchToStandard;

  /// No description provided for @switchStartsLater.
  ///
  /// In en, this message translates to:
  /// **'{price}/month · starts when your current period ends'**
  String switchStartsLater(String price);

  /// No description provided for @switchScheduled.
  ///
  /// In en, this message translates to:
  /// **'You\'ll move to Standard when your current period ends.'**
  String get switchScheduled;

  /// No description provided for @switchPlanned.
  ///
  /// In en, this message translates to:
  /// **'Switch to Standard planned'**
  String get switchPlanned;

  /// No description provided for @switchStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}'**
  String switchStartsOn(String date);

  /// No description provided for @switchAtPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'Starts when your current period ends'**
  String get switchAtPeriodEnd;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
