// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabLive => 'Live';

  @override
  String get tabAi => 'AI';

  @override
  String get tabBasic => 'Basic';

  @override
  String get photoTranslationTitle => 'Photo Translation';

  @override
  String get photoTranslationUpsell =>
      'Translating text in photos is available on the Standard and Premium plans.';

  @override
  String get chooseTargetFirst => 'Choose a target language first.';

  @override
  String get translate => 'Translate';

  @override
  String get welcomeHeadline => 'Translate it. Save it. Learn it.';

  @override
  String get welcomeSubtitle =>
      'Translate with AI, save the words you meet and learn them with spaced repetition.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get signInAndSync => 'Sign in and Sync';

  @override
  String get signIn => 'Sign In';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get googleLoginFailed => 'Google Login failed';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get legalPrefix => 'By continuing you agree to the ';

  @override
  String get legalAnd => ' and ';

  @override
  String get legalSuffix => '.';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get userFallback => 'User';

  @override
  String get guest => 'Guest';

  @override
  String get signInToSyncProgress => 'Sign in to sync your progress';

  @override
  String get helpFaq => 'Help & FAQ';

  @override
  String get contactUs => 'Contact us';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'Your account, decks, cards, favorites and history are deleted on all devices. This cannot be undone.\n\nAn App Store subscription is not cancelled by this; manage it in Settings > your name > Subscriptions.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get syncing => 'Syncing...';

  @override
  String get synced => 'Synced';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get syncAcrossDevices => 'Sync your data across devices';

  @override
  String get syncFailedRetry => 'Sync failed. Please try again.';

  @override
  String get syncFailedConnection =>
      'Sync failed. Please check your connection and try again.';

  @override
  String get synchronize => 'Synchronize';

  @override
  String get syncSignInBody =>
      'Sign in to sync your decks, favorites and history across all your devices.';

  @override
  String get faqQ1 => 'How many translations can I make?';

  @override
  String get faqA1 =>
      'Free: 10 AI translations a day. Standard and Premium: unlimited. Basic translation runs on your phone and is always free.';

  @override
  String get faqQ2 => 'Do my photos leave my phone?';

  @override
  String get faqA2 =>
      'No. The text is read on your phone and only that text is sent to be translated.';

  @override
  String get faqQ3 => 'What is Live translation?';

  @override
  String get faqA3 =>
      'Premium translates speech as it is spoken, with captions: 60 minutes a month (5 minutes in the free trial). The minutes renew every month.';

  @override
  String get faqQ4 => 'How does Study with AI work?';

  @override
  String get faqA4 =>
      'Premium: AI writes a new sentence for each of 10 to 30 words from a deck, and you fill in the blank. Each word gets two tries. A new session can start 3 hours after the last one began.';

  @override
  String get faqQ5 => 'How do I sync my decks between devices?';

  @override
  String get faqA5 => 'Sign in on the Profile page, then tap Sync Now.';

  @override
  String get faqQ6 => 'Can I translate without internet?';

  @override
  String get faqA6 =>
      'Yes, on the Basic page. Each language downloads once (about 30 MB) and then works offline.';

  @override
  String get faqQ7 => 'How do I cancel my subscription?';

  @override
  String get faqA7 =>
      'On your iPhone: Settings > your name > Subscriptions. Deleting the app or your account does not cancel it.';

  @override
  String get stillNeedHelp => 'Still need help?';

  @override
  String get decksTitle => 'Decks';

  @override
  String get newDeck => 'New Deck';

  @override
  String get createFirstDeck => 'Create your first deck to start learning!';

  @override
  String get deckName => 'Deck Name';

  @override
  String get create => 'Create';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get addCard => 'Add Card';

  @override
  String get browseCards => 'Browse Cards';

  @override
  String get deckSettings => 'Deck Settings';

  @override
  String get deleteDeck => 'Delete Deck';

  @override
  String get deleteDeckTitle => 'Delete Deck?';

  @override
  String deleteDeckBody(String name) {
    return 'Delete \"$name\" and all its cards?';
  }

  @override
  String get deleteDeckEndsSession => ' Its Study with AI session ends too.';

  @override
  String get dailyNewLimit => 'Daily New Cards Limit';

  @override
  String get dailyReviewLimit => 'Daily Reviews Limit';

  @override
  String get save => 'Save';

  @override
  String deleteCardsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count cards?',
      one: 'Delete 1 card?',
    );
    return '$_temp0';
  }

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get noCardsYet => 'No cards yet';

  @override
  String get featTranslations => 'Unlimited AI translations';

  @override
  String get featTranslationsDetail =>
      'Standard, formal and slang versions of every sentence.';

  @override
  String get featPhoto => 'AI photo translation';

  @override
  String get featPhotoDetail =>
      'Point the camera at signs, menus and documents.';

  @override
  String get featPhotoWords => 'Words from photos to your decks';

  @override
  String get featPhotoWordsDetail =>
      'AI picks out the useful words; add them in one tap.';

  @override
  String get featDecks => 'Unlimited decks and cards';

  @override
  String get featDecksDetail =>
      'Save every word you want to learn and study it later.';

  @override
  String get featLive => 'AI Live translation';

  @override
  String get featLiveDetail =>
      'Speech translated as it is spoken, keeping tone and emphasis, with live captions. 60 min/month';

  @override
  String get studyWithAi => 'Study with AI';

  @override
  String get featStudyDetail =>
      'AI writes new sentences with your saved words; you fill in the blanks.';

  @override
  String get comingSoon => 'Coming soon — subscriptions aren\'t live yet.';

  @override
  String get plansHeadline => 'Turn every translation\ninto a lesson.';

  @override
  String get plansTrialLine => 'Try any plan free for 14 days. Cancel anytime.';

  @override
  String yourPlanLine(String tier) {
    return 'Your plan: $tier';
  }

  @override
  String get recommended => 'Recommended';

  @override
  String get liveTrialNote =>
      '* The Premium trial includes 5 minutes of Live translation.';

  @override
  String get trialTerms =>
      'After the 14-day free trial, the subscription starts automatically unless you cancel at least 24 hours before the trial ends. One free trial per account. ';

  @override
  String get renewalTerms =>
      'Subscriptions renew automatically each month at the price shown unless you cancel at least 24 hours before the current period ends. Payment is charged to your Apple ID. You can manage or cancel your subscription in your App Store account settings.';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get includedInPremium => 'Included in Premium';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String perMonthCancelAnytime(String price) {
    return '$price/month · cancel anytime';
  }

  @override
  String get startTrial => 'Start 14-day free trial';

  @override
  String thenPerMonth(String price) {
    return 'then $price/month · cancel anytime';
  }

  @override
  String get yourPlan => 'Your plan';

  @override
  String get fourteenDaysFree => '14 days free';

  @override
  String planSemantics(String name, String price) {
    return '$name, $price per month';
  }

  @override
  String pricePerMonth(String price) {
    return '$price/month';
  }

  @override
  String get trialToday => 'Today';

  @override
  String trialTodayDetail(String name) {
    return 'Full access to $name starts.';
  }

  @override
  String get trialDay12 => 'Day 12';

  @override
  String get trialDay12Detail => 'We\'ll remind you that your trial is ending.';

  @override
  String get trialDay14 => 'Day 14';

  @override
  String trialDay14Detail(String price) {
    return 'Your subscription starts at $price/month unless you cancel.';
  }

  @override
  String get howTrialWorks => 'How the free trial works';

  @override
  String get tierFree => 'Free';

  @override
  String get tierStandardTrial => 'Standard (free trial)';

  @override
  String get tierPremiumTrial => 'Premium (free trial)';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String get liveConnecting => 'Connecting…';

  @override
  String get liveListening => 'Listening';

  @override
  String get liveStopped => 'Stopped';

  @override
  String get liveReady => 'Ready';

  @override
  String get muteVoice => 'Mute translated voice';

  @override
  String get unmute => 'Unmute';

  @override
  String get clear => 'Clear';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String minutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String secondsLeft(int seconds) {
    return '$seconds s left';
  }

  @override
  String trialTime(String time) {
    return 'Trial · $time';
  }

  @override
  String get startSpeaking => 'Start speaking';

  @override
  String get liveTitle => 'AI Live Translation';

  @override
  String get liveActiveHint =>
      'The translation appears here as the speaker talks.';

  @override
  String get liveIdleHint =>
      'Tap the mic and let someone speak. AI translates as they talk, keeping their tone and emphasis, and writes it here too.';

  @override
  String liveTrialIncludes(int minutes) {
    return 'Your trial includes $minutes minutes of Live. Premium includes 60 minutes every month.';
  }

  @override
  String get micOff =>
      'Microphone access is off. Allow it in Settings > Privacy > Microphone.';

  @override
  String get trialMinutesUsedShort =>
      'You\'ve used your trial minutes. Premium includes 60 minutes of Live translation every month.';

  @override
  String get liveMonthUsed =>
      'You have used this month\'s live translation time.';

  @override
  String liveMonthUsedResets(int day, int month) {
    return 'You have used this month\'s live translation time. It resets on $day/$month.';
  }

  @override
  String get liveStoppedRetry =>
      'Live translation stopped. Tap the mic to try again.';

  @override
  String get trialMinutesUsedTitle => 'Trial minutes used';

  @override
  String get trialMinutesUsedBody =>
      'You\'ve used your free trial minutes of Live translation. Premium includes 60 minutes every month once your subscription starts.';

  @override
  String get ok => 'OK';

  @override
  String get couldNotEndSession =>
      'Could not end the session. Check your connection.';

  @override
  String get deckNotFoundEnd =>
      'The deck wasn\'t found. You can end the session instead.';

  @override
  String continueProgress(int done, int total) {
    return 'Continue · $done/$total';
  }

  @override
  String addMoreWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count more words',
      one: 'Add 1 more word',
    );
    return '$_temp0';
  }

  @override
  String get needsTenWords =>
      'Study with AI needs a deck with at least 10 words.';

  @override
  String get pickDeck => 'Pick a deck. Each session practises 10 of its words.';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get deckNotOnPhone => 'Deck not on this phone';

  @override
  String missingDeckIntro(String deck) {
    return 'This session is from \"$deck\", which isn\'t on this phone. ';
  }

  @override
  String get missingDeckSync => 'Sync to bring it back, or end the session. ';

  @override
  String get missingDeckEndNote =>
      'Ending it starts the usual break before the next session.';

  @override
  String get syncNowLower => 'Sync now';

  @override
  String get endSession => 'End session';

  @override
  String get finishSessionTitle => 'End this session?';

  @override
  String finishSessionBody(int hours) {
    return 'The words you answered are saved. The next session opens $hours hours after this one began.';
  }

  @override
  String get nextSession => 'Next session';

  @override
  String get readyNow => 'Ready now';

  @override
  String get breakNote =>
      'Words stick better with a break between sessions. Meanwhile you can review them with flashcards.';

  @override
  String reviewWithFlashcards(String deck) {
    return 'Review $deck with flashcards';
  }

  @override
  String get sessionComplete => 'Session complete';

  @override
  String firstTryCount(int count) {
    return '$count first try';
  }

  @override
  String secondTryCount(int count) {
    return '$count on the second try';
  }

  @override
  String missedCount(int count) {
    return '$count missed';
  }

  @override
  String get nextSessionIn => 'Next session in ';

  @override
  String get reviewWithFlashcardsShort => 'Review with flashcards';

  @override
  String get done => 'Done';

  @override
  String get gettingWordsReady => 'Getting your words ready';

  @override
  String get studyIsPremium => 'Study with AI is part of Premium.';

  @override
  String nextSessionStartsIn(String time) {
    return 'Your next session starts in $time.';
  }

  @override
  String get seePlans => 'See plans';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noInternet => 'No internet connection.';

  @override
  String get tooManyMessages =>
      'Too many messages at once. Wait a moment and try again.';

  @override
  String get aiBusy => 'The AI is busy right now. Try again in a few seconds.';

  @override
  String get studyUnavailable =>
      'Study with AI is unavailable right now. Try again later.';

  @override
  String get replyTooLong => 'The reply took too long. Try again.';

  @override
  String get couldNotGetReply => 'Couldn\'t get a reply. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get typeAnswer => 'Type the missing word';

  @override
  String get errConnectionTitle => 'Connection Error';

  @override
  String get errConnectionMsg =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errUnavailableTitle => 'Service Unavailable';

  @override
  String get errUnavailableMsg =>
      'Translation is temporarily unavailable. Please try again later.';

  @override
  String get errBusyTitle => 'AI Is Busy';

  @override
  String get errBusyMsg =>
      'Too many requests right now. Try again in a few seconds.';

  @override
  String get errTimeoutTitle => 'Took Too Long';

  @override
  String get errTimeoutMsg =>
      'The translation took too long. Please try again.';

  @override
  String get errBlockedTitle => 'Can\'t Translate This';

  @override
  String get errBlockedMsg => 'This text couldn\'t be translated.';

  @override
  String get errFailedTitle => 'Something Went Wrong';

  @override
  String get errFailedMsg =>
      'Translation could not be completed. Please try again.';

  @override
  String get listening => 'Listening...';

  @override
  String get enterText => 'Enter text';

  @override
  String get dailyLimitTitle => 'Daily Limit Reached';

  @override
  String get dailyLimitBody =>
      'You\'ve used your 10 free AI translations for today. You can keep using offline translation, or upgrade for unlimited AI translations.';

  @override
  String get slowDownTitle => 'Slow Down';

  @override
  String get slowDownBody =>
      'You\'re sending requests too fast. Please wait a few seconds and try again.';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get deckLimitTitle => 'Deck Limit Reached';

  @override
  String deckLimitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The free plan includes $count decks. Upgrade for unlimited decks and cards.',
      one:
          'The free plan includes 1 deck. Upgrade for unlimited decks and cards.',
    );
    return '$_temp0';
  }

  @override
  String get cardLimitTitle => 'Card Limit Reached';

  @override
  String cardLimitBody(int count) {
    return 'The free plan allows up to $count cards per deck. Upgrade for unlimited cards.';
  }

  @override
  String get backToDecks => 'Back to Decks';

  @override
  String get sessionFinished => 'Session Finished!';

  @override
  String get noCardsAvailable => 'No cards available';

  @override
  String cardProgress(int index, int total) {
    return 'Card $index / $total';
  }

  @override
  String get rateAgain => '🔴 ← AGAIN';

  @override
  String get rateGood => '🟢 GOOD →';

  @override
  String get rateEasy => '🔵 ↑ EASY';

  @override
  String get rateHard => '🟠 ↓ HARD';

  @override
  String get showAnswer => 'SHOW ANSWER';

  @override
  String get swipeToRate => 'Swipe to Rate';

  @override
  String get rateLegend => '🔴 Again  •  🟠 Hard  •  🟢 Good  •  🔵 Easy';

  @override
  String get historyTitle => 'History';

  @override
  String get clearAll => 'Clear All';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get clearHistoryTitle => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to delete all history?';

  @override
  String get translationHint => 'Translation';

  @override
  String get toneStandard => 'Standard';

  @override
  String get toneFormal => 'Formal';

  @override
  String get toneSlang => 'Slang';

  @override
  String get toneLabel => 'Tone';

  @override
  String get saveToDeck => 'Save to Deck';

  @override
  String get noDecksFound => 'No decks found.\nCreate a deck first.';

  @override
  String get saveFlashcard => 'Save Flashcard';

  @override
  String saveWordToDeck(String deck) {
    return 'Save word to $deck?';
  }

  @override
  String get consentTitle => 'Before you use AI';

  @override
  String get consentBody1 =>
      'AI translation, photo translation, Live and Study with AI send the text you enter, the text read from your photo, your voice in Live and your deck\'s words to Google Gemini to be processed.';

  @override
  String get consentBody2 =>
      'Your photos never leave your phone. Basic translation works on your phone without this.';

  @override
  String get notNow => 'Not now';

  @override
  String get allow => 'Allow';

  @override
  String get cardFront => 'Front';

  @override
  String get cardBack => 'Back';

  @override
  String get add => 'Add';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get restartTitle => 'Restart Required';

  @override
  String get restartBody =>
      'Please close and reopen the app to keep translating as a guest, or sign back in.';

  @override
  String get didYouMean => 'Did you mean: ';

  @override
  String get translateFrom => 'Translate from: ';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'German';

  @override
  String get langFrench => 'French';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get langItalian => 'Italian';

  @override
  String get langRussian => 'Russian';

  @override
  String get langJapanese => 'Japanese';

  @override
  String get langChinese => 'Chinese';

  @override
  String get langKorean => 'Korean';

  @override
  String get langArabic => 'Arabic';

  @override
  String get langPortuguese => 'Portuguese';

  @override
  String get langHindi => 'Hindi';

  @override
  String get langUrdu => 'Urdu';

  @override
  String get langPersian => 'Persian';

  @override
  String get langDutch => 'Dutch';

  @override
  String get langSwedish => 'Swedish';

  @override
  String get langNorwegian => 'Norwegian';

  @override
  String get langDanish => 'Danish';

  @override
  String get langFinnish => 'Finnish';

  @override
  String get langPolish => 'Polish';

  @override
  String get langGreek => 'Greek';

  @override
  String get langHebrew => 'Hebrew';

  @override
  String get langTurkish => 'Turkish';

  @override
  String get recents => 'RECENTS';

  @override
  String get allLanguages => 'ALL LANGUAGES';

  @override
  String get select => 'Select';

  @override
  String get couldNotTakePhoto => 'Could not take the photo. Try again.';

  @override
  String get couldNotOpenPhotos => 'Could not open your photos.';

  @override
  String get tips => 'Tips';

  @override
  String get more => 'More';

  @override
  String get copyTranslation => 'Copy translation';

  @override
  String get copyOriginal => 'Copy original text';

  @override
  String get translationCopied => 'Translation copied';

  @override
  String get originalCopied => 'Original text copied';

  @override
  String get tip1 => 'Hold the phone flat over the text.';

  @override
  String get tip2 => 'Good light helps; use the flash in the dark.';

  @override
  String get tip3 => 'Tap the screen to focus.';

  @override
  String get tip4 => 'Pinch to zoom in on small text.';

  @override
  String get tip5 => 'Press and hold a translation to select and copy it.';

  @override
  String get tip6 => 'Swipe up the word list to add words to a deck.';

  @override
  String get tipsTitle => 'Tips for better results';

  @override
  String get back => 'Back';

  @override
  String get swapLanguages => 'Swap languages';

  @override
  String get cameraOffTitle => 'Camera access is off';

  @override
  String get cameraOffBody =>
      'Allow camera access for Decklingo in Settings > Privacy > Camera, or pick a photo from your gallery.';

  @override
  String get cameraUnavailableTitle => 'Camera unavailable';

  @override
  String get cameraUnavailableBody =>
      'The camera could not be started on this device. You can still pick a photo from your gallery.';

  @override
  String get holdStraight =>
      'Hold the phone straight and parallel to the text for the best fit.';

  @override
  String get flashOff => 'Flash off';

  @override
  String get flashAuto => 'Flash auto';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String linesTranslatedTo(int count, String language) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines translated to $language',
      one: '1 line translated to $language',
    );
    return '$_temp0';
  }

  @override
  String get showTranslation => 'Show translation';

  @override
  String get showOriginal => 'Show original';

  @override
  String get retake => 'Retake';

  @override
  String get close => 'Close';

  @override
  String get words => 'Words';

  @override
  String get noWordsFound => 'No words to add were found in this photo.';

  @override
  String get addToDeck => 'Add to deck';

  @override
  String get readingText => 'Reading text…';

  @override
  String translatingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Translating $count lines…',
      one: 'Translating 1 line…',
    );
    return '$_temp0';
  }

  @override
  String get noTextFound =>
      'No text found. Try a closer, sharper photo, or check the source language.';

  @override
  String get couldNotOpenPhoto => 'Could not open the photo. Please retake it.';

  @override
  String unsupportedPhotoLanguage(String language) {
    return 'Text in $language can\'t be read from photos yet. Choose another source language.';
  }

  @override
  String get unsupportedPhotoLanguageUnknown =>
      'Text in this language can\'t be read from photos yet. Choose another source language.';

  @override
  String get couldNotReadText => 'Could not read the text. Please try again.';

  @override
  String get tooManyPhotos =>
      'Too many photo translations. Wait a few seconds and retry.';

  @override
  String get photoNeedsStandard =>
      'Photo translation is available on the Standard plan.';

  @override
  String get restartOrSignIn => 'Restart the app or sign in to continue.';

  @override
  String welcomeBackWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Welcome back, $count words to go.',
      one: 'Welcome back, 1 word to go.',
    );
    return '$_temp0';
  }

  @override
  String studyGreeting(String deck, int count) {
    return 'Let\'s study $count words from \"$deck\". Type the missing word in each sentence.';
  }

  @override
  String get studyCorrect => 'Correct!';

  @override
  String get studyTryAgain => 'Not quite. Try again.';

  @override
  String studyAnswerWas(String word) {
    return 'The answer was \"$word\".';
  }

  @override
  String get authEmailInUse => 'Email is already registered.';

  @override
  String get authInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authWeakPassword => 'Password too weak (min 6 chars).';

  @override
  String get authInvalidCredentials => 'Invalid email or password.';

  @override
  String get authNetwork => 'Network error. Check your connection.';

  @override
  String get authInvalidInput => 'Invalid input. Please check your details.';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Please try again.';

  @override
  String get failedLoadDecks => 'Failed to load decks';

  @override
  String get failedAddDeck => 'Failed to add deck';

  @override
  String get failedDeleteDeck => 'Failed to delete deck';

  @override
  String get failedAddCard => 'Failed to add card';

  @override
  String cardTooLong(int word, int translation) {
    return 'Too long for a card: the word can be up to $word characters, the translation up to $translation.';
  }

  @override
  String get failedDeleteCards => 'Failed to delete cards';

  @override
  String get failedUpdateDeckSettings => 'Failed to update deck settings';

  @override
  String get failedUpdateDeckLimits => 'Failed to update deck limits';

  @override
  String get failedLoadLimits => 'Failed to load account limits';

  @override
  String get failedLoadFavorites => 'Failed to load favorites';

  @override
  String get failedSaveFavorite => 'Failed to save favorite';

  @override
  String get failedDeleteFavorite => 'Failed to delete favorite';

  @override
  String get geminiNoInternet =>
      'No internet connection. Please check your network and try again.';

  @override
  String get dailyAiLimit =>
      'Daily AI limit reached. Try offline mode or upgrade for unlimited translations.';

  @override
  String get tooManyRequests =>
      'Too many requests! Please wait a few seconds and try again.';

  @override
  String get aiOverloaded =>
      'AI servers are currently overloaded. Please wait a few seconds and try again.';

  @override
  String errorOccurred(String details) {
    return 'An error occurred: $details';
  }

  @override
  String get failedLoadHistory => 'Failed to load history';

  @override
  String get failedSaveHistory => 'Failed to save history item';

  @override
  String get failedDeleteHistory => 'Failed to delete history item';

  @override
  String get failedClearHistory => 'Failed to clear history';

  @override
  String failedDownloadModel(String language) {
    return 'Failed to download model for $language';
  }

  @override
  String get failedInitTranslator => 'Failed to initialize translator';

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get failedInitStudy => 'Failed to initialize study session';

  @override
  String get failedSaveRating => 'Failed to save rating';
}
