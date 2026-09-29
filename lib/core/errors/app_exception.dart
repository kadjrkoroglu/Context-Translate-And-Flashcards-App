abstract class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, {this.details});

  @override
  String toString() =>
      '$runtimeType: $message${details != null ? ' ($details)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.details});
}

class FirebaseDataException extends AppException {
  const FirebaseDataException(super.message, {super.details});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.details});
}

class GeneralException extends AppException {
  const GeneralException(super.message, {super.details});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.details, this.code});

  final String? code;
}

/// A 429 from the backend. [window] tells the two cases apart:
/// 'day' is the free tier's daily cap, 'burst' is Standard/Premium's
/// short-lived token bucket, and null is a generic anti-abuse rate limit.
class QuotaExceededException extends AppException {
  const QuotaExceededException(
    super.message, {
    super.details,
    this.window,
    this.resetsAt,
    this.retryAfterSeconds,
  });

  final String? window;
  final DateTime? resetsAt;
  final int? retryAfterSeconds;

  bool get isDailyLimit => window == 'day';
}
