import 'app_exception.dart';

class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.cause,
  });

  @override
  String toString() {
    if (code != null) {
      return 'FirestoreException($code): $message';
    }

    return 'FirestoreException: $message';
  }
}