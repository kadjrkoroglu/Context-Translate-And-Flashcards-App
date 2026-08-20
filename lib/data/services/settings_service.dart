import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keySourceLang = 'ml_source_lang';
  static const String _keyTargetLang = 'ml_target_lang';
  static const String _keyGeminiSourceLang = 'gemini_source_lang';
  static const String _keyGeminiLang = 'gemini_target_lang';
  static const String _keyRecentLangs = 'recent_languages';
  static const String _keyThemeMode = 'theme_mode';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Recent Languages
  List<String> get recentLanguages =>
      _prefs.getStringList(_keyRecentLangs) ?? [];

  Future<void> addRecentLanguage(String lang) async {
    if (lang == '-') return;

    final current = recentLanguages;
    current.remove(lang);
    current.insert(0, lang);

    if (current.length > 3) {
      current.removeLast();
    }

    await _prefs.setStringList(_keyRecentLangs, current);
  }

  // ML Languages
  String get mlSourceLang => _prefs.getString(_keySourceLang) ?? 'English';
  Future<void> setMlSourceLang(String lang) =>
      _prefs.setString(_keySourceLang, lang);

  String get mlTargetLang => _prefs.getString(_keyTargetLang) ?? '-';
  Future<void> setMlTargetLang(String lang) =>
      _prefs.setString(_keyTargetLang, lang);

  // Gemini Language
  String get geminiSourceLang => _prefs.getString(_keyGeminiSourceLang) ?? 'English';
  Future<void> setGeminiSourceLang(String lang) =>
      _prefs.setString(_keyGeminiSourceLang, lang);

  String get geminiTargetLang => _prefs.getString(_keyGeminiLang) ?? '-';
  Future<void> setGeminiTargetLang(String lang) =>
      _prefs.setString(_keyGeminiLang, lang);

  // Theme Mode
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  // First Run logic
  static const String _keyFirstRun = 'is_first_run';
  bool get isFirstRun => _prefs.getBool(_keyFirstRun) ?? true;
  Future<void> setFirstRunComplete() => _prefs.setBool(_keyFirstRun, false);
}
