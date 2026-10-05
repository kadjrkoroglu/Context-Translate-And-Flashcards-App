import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/api_config.dart';

class AccountService {
  static const String _url = '${ApiConfig.baseUrl}/account';

  /// The server deletes the login, the synced data and our records.
  Future<void> deleteAccount() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const AuthException('Sign in required to delete the account');
    }
    try {
      final response = await http.delete(
        Uri.parse(_url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw GeneralException(
          'Account deletion failed',
          details: response.body,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', details: e.toString());
    } on http.ClientException catch (e) {
      throw NetworkException('Network error', details: e.toString());
    }
  }
}
