import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/core/errors/app_exception.dart';

void main() {
  group('NetworkException', () {
    test('carries the correct message', () {
      const exception = NetworkException('No connection');
      expect(exception.message, 'No connection');
    });

    test('is an instance of AppException', () {
      const exception = NetworkException('No connection');
      expect(exception, isA<AppException>());
    });

    test('message is not empty', () {
      const exception = NetworkException('No connection');
      expect(exception.message, isNotEmpty);
    });

    test('details are included in toString', () {
      const exception = NetworkException('No connection', details: 'timeout');
      expect(exception.toString(), contains('timeout'));
    });

    test('toString omits details when null', () {
      const exception = NetworkException('No connection');
      expect(exception.toString(), isNot(contains('(')));
    });
  });

  group('FirebaseDataException', () {
    test('carries the correct message', () {
      const exception = FirebaseDataException('Write failed');
      expect(exception.message, 'Write failed');
    });

    test('is an instance of AppException', () {
      const exception = FirebaseDataException('Write failed');
      expect(exception, isA<AppException>());
    });

    test('message is not empty', () {
      const exception = FirebaseDataException('Write failed');
      expect(exception.message, isNotEmpty);
    });

    test('details are included in toString', () {
      const exception = FirebaseDataException('Write failed', details: 'permission-denied');
      expect(exception.toString(), contains('permission-denied'));
    });

    test('toString omits details when null', () {
      const exception = FirebaseDataException('Write failed');
      expect(exception.toString(), isNot(contains('(')));
    });
  });

  group('StorageException', () {
    test('carries the correct message', () {
      const exception = StorageException('Read failed');
      expect(exception.message, 'Read failed');
    });

    test('is an instance of AppException', () {
      const exception = StorageException('Read failed');
      expect(exception, isA<AppException>());
    });

    test('message is not empty', () {
      const exception = StorageException('Read failed');
      expect(exception.message, isNotEmpty);
    });

    test('details are included in toString', () {
      const exception = StorageException('Read failed', details: 'corrupted');
      expect(exception.toString(), contains('corrupted'));
    });

    test('toString omits details when null', () {
      const exception = StorageException('Read failed');
      expect(exception.toString(), isNot(contains('(')));
    });
  });

  group('GeneralException', () {
    test('carries the correct message', () {
      const exception = GeneralException('Unknown error');
      expect(exception.message, 'Unknown error');
    });

    test('is an instance of AppException', () {
      const exception = GeneralException('Unknown error');
      expect(exception, isA<AppException>());
    });

    test('message is not empty', () {
      const exception = GeneralException('Unknown error');
      expect(exception.message, isNotEmpty);
    });

    test('details are included in toString', () {
      const exception = GeneralException('Unknown error', details: 'stack trace here');
      expect(exception.toString(), contains('stack trace here'));
    });

    test('toString omits details when null', () {
      const exception = GeneralException('Unknown error');
      expect(exception.toString(), isNot(contains('(')));
    });
  });

  group('toString format', () {
    test('contains runtimeType and message', () {
      const exception = NetworkException('Something failed');
      expect(exception.toString(), 'NetworkException: Something failed');
    });

    test('contains runtimeType, message, and details when provided', () {
      const exception = StorageException('Read failed', details: 'not found');
      expect(exception.toString(), 'StorageException: Read failed (not found)');
    });
  });
}
