import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/api_config.dart';

class EntitlementsService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/entitlements';

  Future<Map<String, dynamic>> fetchEntitlements() => _send(refresh: false);

  /// Has the server read the plan from RevenueCat first (after a purchase).
  Future<Map<String, dynamic>> refreshEntitlements() => _send(refresh: true);

  Future<Map<String, dynamic>> _send({required bool refresh}) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const AuthException('Sign in required to fetch entitlements');
      }

      final headers = {'Authorization': 'Bearer $token'};
      final response = refresh
          ? await http.post(Uri.parse('$_baseUrl/refresh'), headers: headers)
          : await http.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode != 200) {
        throw GeneralException('Failed to fetch entitlements', details: response.body);
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', details: e.toString());
    } on http.ClientException catch (e) {
      throw NetworkException('Network error while fetching entitlements', details: e.toString());
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException('Failed to fetch entitlements', details: e.toString());
    }
  }
}
