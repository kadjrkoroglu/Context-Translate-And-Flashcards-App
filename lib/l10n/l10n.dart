import 'dart:ui';

import 'package:translate_app/core/languages.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Turkish on a Turkish phone, English everywhere else.
Locale appLocale(Locale? device) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

/// Strings for code without a BuildContext (view models, services).
AppLocalizations get l10n =>
    lookupAppLocalizations(appLocale(PlatformDispatcher.instance.locale));

/// A language as shown on screen; the stored value stays the English name.
String languageLabel(String value, [AppLocalizations? strings]) {
  final t = strings ?? l10n;
  return switch (value) {
    autoDetect => t.autoDetect,
    'English' => t.langEnglish,
    'German' => t.langGerman,
    'French' => t.langFrench,
    'Spanish' => t.langSpanish,
    'Italian' => t.langItalian,
    'Russian' => t.langRussian,
    'Japanese' => t.langJapanese,
    'Chinese' => t.langChinese,
    'Korean' => t.langKorean,
    'Arabic' => t.langArabic,
    'Portuguese' => t.langPortuguese,
    'Hindi' => t.langHindi,
    'Urdu' => t.langUrdu,
    'Persian' => t.langPersian,
    'Dutch' => t.langDutch,
    'Swedish' => t.langSwedish,
    'Norwegian' => t.langNorwegian,
    'Danish' => t.langDanish,
    'Finnish' => t.langFinnish,
    'Polish' => t.langPolish,
    'Greek' => t.langGreek,
    'Hebrew' => t.langHebrew,
    'Turkish' => t.langTurkish,
    _ => value,
  };
}
