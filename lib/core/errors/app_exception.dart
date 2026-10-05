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
    this.tier,
  });

  final String? window;

  /// The user's plan, when the backend sends it (e.g. 'trial_premium').
  final String? tier;
  final DateTime? resetsAt;
  final int? retryAfterSeconds;

  bool get isDailyLimit => window == 'day';
  bool get isTrial => tier == 'trial_premium';
}

/// 403: the user's plan doesn't include the feature.
class FeatureNotAvailableException extends AppException {
  const FeatureNotAvailableException(super.message, {super.details});
}

enum AiFailure { unavailable, busy, timeout, blocked, failed }

/// The AI service failed; [kind] comes from the backend's error code.
class AiServiceException extends AppException {
  const AiServiceException(super.message, this.kind, {super.details});

  final AiFailure kind;

  static AiFailure kindFromCode(String? code) => switch (code) {
    'ai_unavailable' => AiFailure.unavailable,
    'ai_busy' => AiFailure.busy,
    'ai_timeout' => AiFailure.timeout,
    'ai_blocked' => AiFailure.blocked,
    _ => AiFailure.failed,
  };
}

class MicrophoneDeniedException extends AppException {
  const MicrophoneDeniedException(super.message);
}

/// No OCR model for this language's script (e.g. Hebrew).
class UnsupportedLanguageException extends AppException {
  const UnsupportedLanguageException(super.message, {this.language});

  final String? language;
}
