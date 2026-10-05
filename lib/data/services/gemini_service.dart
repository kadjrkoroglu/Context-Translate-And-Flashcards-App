import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:translate_app/core/languages.dart';
import 'package:http/http.dart' as http;
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/api_config.dart';
import 'package:translate_app/domain/entities/live_session_grant.dart';
import 'package:translate_app/domain/entities/photo_translation.dart';
import 'package:translate_app/domain/entities/study_session.dart';

class GeminiService {
  static const String _translateUrl = '${ApiConfig.baseUrl}/translate';
  static const String _photoUrl = '${ApiConfig.baseUrl}/translate/photo';
  static const String _liveSessionUrl = '${ApiConfig.baseUrl}/live/session';
  static const String _studyUrl = '${ApiConfig.baseUrl}/study';

  Future<List<String>> translateText(String text, String targetLanguage) async {
    final data = await _post(_translateUrl, {
      'text': text,
      'targetLanguage': targetLanguage,
    });
    return (data['translations'] as List<dynamic>)
        .map((t) => t.toString())
        .toList();
  }

  /// Only the text read on the device is sent, never the photo.
  Future<PhotoTranslation> translatePhotoLines(
    List<String> lines,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final data = await _post(_photoUrl, {
      'lines': lines,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    });
    return PhotoTranslation(
      translations: (data['translations'] as List<dynamic>)
          .map((t) => t.toString())
          .toList(),
      words: [
        for (final w in data['words'] as List<dynamic>? ?? const [])
          if (w is Map && w['word'] is String && w['translation'] is String)
            PhotoWord(word: w['word'], translation: w['translation']),
      ],
    );
  }

  /// Reserves Live time; returns a token for Gemini (the key stays on the server).
  Future<LiveSessionGrant> startLiveSession(String targetLanguageCode) async {
    final data = await _post(_liveSessionUrl, {
      'targetLanguageCode': targetLanguageCode,
    });
    return LiveSessionGrant.fromJson(data);
  }

  /// Gives back unused time; returns seconds left this month.
  Future<int?> endLiveSession(String sessionId) async {
    final data = await _post('$_liveSessionUrl/end', {'sessionId': sessionId});
    return data['remainingSeconds'] as int?;
  }

  Future<StudyState> fetchStudyState() async =>
      StudyState.fromJson(await _send(_studyUrl));

  /// Starts a session with these cards, or returns the unfinished one.
  Future<StudyStart> startStudy({
    required String deckId,
    required String deckName,
    required List<({String id, String word, String translation})> cards,
  }) async {
    final data = await _post('$_studyUrl/start', {
      'deckId': deckId,
      'deckName': deckName,
      'cards': [
        for (final c in cards)
          {'id': c.id, 'word': c.word, 'translation': c.translation},
      ],
    });
    return StudyStart.fromJson(data);
  }

  Future<StudyReply> answerStudy(String sessionId, String answer) async {
    final data = await _post('$_studyUrl/answer', {
      'sessionId': sessionId,
      'answer': answer,
    });
    return StudyReply.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> payload,
  ) => _send(url, payload: payload);

  /// GET without [payload], POST with it.
  Future<Map<String, dynamic>> _send(
    String url, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const AuthException('Sign in required to translate');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = payload == null
          ? await http.get(Uri.parse(url), headers: headers)
          : await http.post(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(payload),
            );

      if (response.statusCode == 429) {
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          // Not every 429 (e.g. the plain IP rate limiter) returns JSON we recognize.
        }
        throw QuotaExceededException(
          body?['error'] as String? ?? 'Too many requests, try again shortly',
          details: response.body,
          window: body?['window'] as String?,
          resetsAt: body?['resetsAt'] != null
              ? DateTime.tryParse(body!['resetsAt'] as String)
              : null,
          retryAfterSeconds: body?['retryAfterSeconds'] as int?,
          tier: body?['tier'] as String?,
        );
      }
      if (response.statusCode == 403) {
        throw FeatureNotAvailableException(
          'Not available on your plan',
          details: response.body,
        );
      }
      if (response.statusCode != 200) {
        String? code;
        try {
          code =
              (jsonDecode(response.body) as Map<String, dynamic>)['error']
                  as String?;
        } catch (_) {}
        throw AiServiceException(
          'Translation failed',
          AiServiceException.kindFromCode(code),
          details: response.body,
          code: code,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
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
