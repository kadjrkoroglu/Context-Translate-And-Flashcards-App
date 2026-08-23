abstract class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, {this.details});

  @override
  String toString() => '$runtimeType: $message${details != null ? ' ($details)' : ''}';
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
