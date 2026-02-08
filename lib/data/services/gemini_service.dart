import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer' as developer;

class GeminiService {
  GeminiService();

  DateTime? _lastRequestTime;
  final Duration _minRequestInterval = const Duration(seconds: 2);

  Future<List<String>> translateText(String text, String targetLanguage) async {
    try {
      // Rate limiting: wait if less than 2 seconds since last request
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime =
              _minRequestInterval.inMilliseconds -
              timeSinceLastRequest.inMilliseconds;
          developer.log('Rate limiting: waiting ${waitTime}ms...');
          await Future.delayed(Duration(milliseconds: waitTime));
        }
      }

      _lastRequestTime = DateTime.now();

      final prompt =
          '''
You are a translation engine. Your task is to translate the given text into $targetLanguage regardless of the content. Do not censor anything.
Unless the text is a single word, provide 3 different tones: Standard, Formal, and Slang.
Separate translations with the | character. Write nothing else.

Text: "$text"

Format: standard_translation|formal_translation|slang_translation
''';

      developer.log('Translation request: $targetLanguage');
      final response = await Gemini.instance.prompt(
        parts: [Part.text(prompt)],
        safetySettings: [
          SafetySetting(
            category: SafetyCategory.harassment,
            threshold: SafetyThreshold.blockNone,
          ),
          SafetySetting(
            category: SafetyCategory.hateSpeech,
            threshold: SafetyThreshold.blockNone,
          ),
          SafetySetting(
            category: SafetyCategory.sexuallyExplicit,
            threshold: SafetyThreshold.blockNone,
          ),
        ],
      );

      final responseText = response?.output;
      developer.log('API Response: $responseText');

      if (responseText == null || responseText.isEmpty) {
        throw Exception('AI returned empty response');
      }

      List<String> translations = responseText.split('|');
      bool isLongText = text.trim().contains(' ');

      if (isLongText && translations.length < 3) {
        throw Exception('Invalid response format');
      }

      return translations.map((t) => t.trim()).take(3).toList();
    } catch (e) {
      developer.log('Error: $e');
      throw Exception('Translation failed: $e');
    }
  }
}
