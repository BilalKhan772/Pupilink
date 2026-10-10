import 'app_exception.dart';

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.cause,
  });

  @override
  String toString() {
    if (code != null) {
      return 'StorageException($code): $message';
    }

    return 'StorageException: $message';
  }
}