import 'package:flutter_tts/flutter_tts.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text, String languageName) async {
    if (text.isEmpty) return;

    final bcpCode = MlLanguages.mapNameToBCP(languageName);

    try {
      await _flutterTts.setLanguage(bcpCode);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      throw GeneralException('Failed to play audio', details: e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      throw GeneralException('Failed to stop audio', details: e.toString());
    }
  }
}
