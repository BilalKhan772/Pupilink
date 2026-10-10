import 'app_exception.dart';

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.cause,
  });

  @override
  String toString() {
    if (code != null) {
      return 'ValidationException($code): $message';
    }

    return 'ValidationException: $message';
  }
}