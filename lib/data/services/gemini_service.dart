import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:translate_app/core/errors/app_exception.dart';

class GeminiService {
  static const String _baseUrl =
      'https://context-translate-api-production.up.railway.app/translate';

  Future<List<String>> translateText(String text, String targetLanguage) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const AuthException('Sign in required to translate');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text, 'targetLanguage': targetLanguage}),
      );

      if (response.statusCode == 429) {
        throw GeneralException('Too many requests, try again shortly');
      }
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
