import 'package:flutter_tts/flutter_tts.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text, String languageName) async {
    if (text.isEmpty) return;

    final bcpCode = MlLanguages.mapNameToBCP(languageName);

    await _flutterTts.setLanguage(bcpCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
