import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MlLanguages {
  static const List<String> languageList = [
    'English',
    'German',
    'French',
    'Spanish',
    'Italian',
    'Russian',
    'Japanese',
    'Chinese',
    'Korean',
    'Arabic',
    'Portuguese',
    'Hindi',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Polish',
    'Greek',
    'Hebrew',
    'Turkish',
  ];

  static TranslateLanguage mapStringToLanguage(String lang) {
    switch (lang) {
      case 'English':
        return TranslateLanguage.english;
      case 'German':
        return TranslateLanguage.german;
      case 'French':
        return TranslateLanguage.french;
      case 'Spanish':
        return TranslateLanguage.spanish;
      case 'Italian':
        return TranslateLanguage.italian;
      case 'Russian':
        return TranslateLanguage.russian;
      case 'Japanese':
        return TranslateLanguage.japanese;
      case 'Chinese':
        return TranslateLanguage.chinese;
      case 'Korean':
        return TranslateLanguage.korean;
      case 'Arabic':
        return TranslateLanguage.arabic;
      case 'Portuguese':
        return TranslateLanguage.portuguese;
      case 'Hindi':
        return TranslateLanguage.hindi;
      case 'Dutch':
        return TranslateLanguage.dutch;
      case 'Swedish':
        return TranslateLanguage.swedish;
      case 'Norwegian':
        return TranslateLanguage.norwegian;
      case 'Danish':
        return TranslateLanguage.danish;
      case 'Finnish':
        return TranslateLanguage.finnish;
      case 'Polish':
        return TranslateLanguage.polish;
      case 'Greek':
        return TranslateLanguage.greek;
      case 'Hebrew':
        return TranslateLanguage.hebrew;
      case 'Turkish':
        return TranslateLanguage.turkish;
      default:
        return TranslateLanguage.english;
    }
  }

  static String? mapBCPToName(String bcpCode) {
    switch (bcpCode) {
      case 'en':
        return 'English';
      case 'de':
        return 'German';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'it':
        return 'Italian';
      case 'ru':
        return 'Russian';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      case 'ko':
        return 'Korean';
      case 'ar':
        return 'Arabic';
      case 'pt':
        return 'Portuguese';
      case 'hi':
        return 'Hindi';
      case 'nl':
        return 'Dutch';
      case 'sv':
        return 'Swedish';
      case 'no':
        return 'Norwegian';
      case 'da':
        return 'Danish';
      case 'fi':
        return 'Finnish';
      case 'pl':
        return 'Polish';
      case 'el':
        return 'Greek';
      case 'he':
        return 'Hebrew';
      case 'tr':
        return 'Turkish';
      default:
        return null;
    }
  }

  static String mapNameToBCP(String name) {
    switch (name) {
      case 'English':
        return 'en';
      case 'German':
        return 'de';
      case 'French':
        return 'fr';
      case 'Spanish':
        return 'es';
      case 'Italian':
        return 'it';
      case 'Russian':
        return 'ru';
      case 'Japanese':
        return 'ja';
      case 'Chinese':
        return 'zh';
      case 'Korean':
        return 'ko';
      case 'Arabic':
        return 'ar';
      case 'Portuguese':
        return 'pt';
      case 'Hindi':
        return 'hi';
      case 'Dutch':
        return 'nl';
      case 'Turkish':
        return 'tr';
      default:
        return 'en';
    }
  }
}
