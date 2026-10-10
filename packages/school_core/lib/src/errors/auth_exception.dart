import 'app_exception.dart';

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.cause,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AuthException($code): $message';
    }

    return 'AuthException: $message';
  }
}