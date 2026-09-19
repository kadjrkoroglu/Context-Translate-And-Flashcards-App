import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:translate_app/core/errors/app_exception.dart';

class GeminiService {
  static const String _baseUrl =
      'https://europe-west1-translateapp-bd410.cloudfunctions.net/translate';

  Future<List<String>> translateText(String text, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'targetLanguage': targetLanguage}),
      );

      if (response.statusCode != 200) {
        throw GeneralException('Translation failed', details: response.body);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final translations = (data['translations'] as List<dynamic>)
          .map((t) => t.toString())
          .toList();

      return translations;
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', details: e.toString());
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error while translating',
        details: e.toString(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException('Translation failed', details: e.toString());
    }
  }
}
