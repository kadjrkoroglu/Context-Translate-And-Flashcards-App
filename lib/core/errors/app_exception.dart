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

/// 429. [window]: 'day' = free daily cap, 'burst' = token bucket,
/// null = generic rate limit.
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

/// 403: the user's plan doesn't include the feature.
class FeatureNotAvailableException extends AppException {
  const FeatureNotAvailableException(super.message, {super.details});
}

class MicrophoneDeniedException extends AppException {
  const MicrophoneDeniedException(super.message);
}

/// No OCR model for this language's script (e.g. Hebrew).
class UnsupportedLanguageException extends AppException {
  const UnsupportedLanguageException(super.message, {this.language});

  final String? language;
}
