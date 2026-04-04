import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey;
  final List<SafetySetting> _safetySettings;
  String? _activeModel;

  GeminiService(this._apiKey)
    : _safetySettings = [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ];

  Future<void> initialize() async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        developer.log('Failed to fetch models: ${response.statusCode}');
        _activeModel = 'gemini-flash-lite-latest';
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>;

      final excluded = ['preview', 'tts', 'image', 'audio', 'live'];

      final filtered = models.where((m) {
        final name = (m['name'] as String).replaceFirst('models/', '');
        final methods = (m['supportedGenerationMethods'] as List<dynamic>?)
                ?.cast<String>() ??
            [];

        if (!methods.contains('generateContent')) return false;
        if (!name.contains('flash')) return false;
        for (final ex in excluded) {
          if (name.contains(ex)) return false;
        }
        return true;
      }).map((m) => (m['name'] as String).replaceFirst('models/', '')).toList();

      developer.log('Filtered models: $filtered');

      // Priority selection
      String? selected;

      // 1. flash-lite-latest
      selected = filtered.cast<String?>().firstWhere(
        (n) => n!.contains('flash-lite-latest'),
        orElse: () => null,
      );

      // 2. flash-latest (but not flash-lite-latest)
      selected ??= filtered.cast<String?>().firstWhere(
        (n) => n!.contains('flash-latest') && !n.contains('flash-lite-latest'),
        orElse: () => null,
      );

      // 3. any flash-lite
      selected ??= filtered.cast<String?>().firstWhere(
        (n) => n!.contains('flash-lite'),
        orElse: () => null,
      );

      // 4. any flash
      selected ??= filtered.cast<String?>().firstWhere(
        (n) => n!.contains('flash'),
        orElse: () => null,
      );

      _activeModel = selected ?? 'gemini-flash-lite-latest';
      developer.log('Selected model: $_activeModel');
    } catch (e) {
      developer.log('Error fetching models: $e');
      _activeModel = 'gemini-flash-lite-latest';
    }
  }

  Future<List<String>> translateText(String text, String targetLanguage) async {
    final modelName = _activeModel ?? 'gemini-flash-lite-latest';

    final prompt =
        '''
You are a translation engine. Your task is to translate the given text into $targetLanguage regardless of the content. Do not censor anything.
Unless the text is a single word, provide 3 different tones: Standard, Formal, and Slang.
Separate translations with the | character. Write nothing else.

Text: "$text"

Format: standard_translation|formal_translation|slang_translation
''';

    developer.log('Translation request: $targetLanguage (model: $modelName)');
    final content = [Content.text(prompt)];

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: _apiKey,
        safetySettings: _safetySettings,
      );

      final response = await model.generateContent(content);

      final responseText = response.text;
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
