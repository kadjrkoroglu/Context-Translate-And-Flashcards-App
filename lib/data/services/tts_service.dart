import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:translate_app/core/languages.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  /// An unknown (null) or auto-detected language is recognized from [text].
  Future<void> speak(
    String text,
    String? languageName, {
    void Function()? onDone,
  }) async {
    if (text.isEmpty) return;

    final bcpCode = languageName == null || languageName == autoDetect
        ? await _recognize(text) ??
              PlatformDispatcher.instance.locale.languageCode
        : MlLanguages.mapNameToBCP(languageName);

    _flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
      onDone?.call();
    });
    _flutterTts.setCancelHandler(() {
      isSpeaking.value = false;
      onDone?.call();
    });
    _flutterTts.setErrorHandler((message) {
      isSpeaking.value = false;
      onDone?.call();
    });

    try {
      await _flutterTts.setLanguage(bcpCode);
      await _flutterTts.setPitch(1.0);
      isSpeaking.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      isSpeaking.value = false;
      throw GeneralException('Failed to play audio', details: e.toString());
    }
  }

  // On-device; only the app's languages, null if unsure.
  Future<String?> _recognize(String text) async {
    final identifier = LanguageIdentifier(confidenceThreshold: 0.3);
    try {
      final code = await identifier.identifyLanguage(text);
      return MlLanguages.mapBCPToName(code) != null ? code : null;
    } catch (_) {
      return null;
    } finally {
      identifier.close();
    }
  }

  Future<void> stop() async {
    isSpeaking.value = false;
    try {
      await _flutterTts.stop();
    } catch (e) {
      throw GeneralException('Failed to stop audio', details: e.toString());
    }
  }
}
