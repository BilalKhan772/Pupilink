import 'app_exception.dart';

class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.cause,
  });

  @override
  String toString() {
    if (code != null) {
      return 'PermissionException($code): $message';
    }

    return 'PermissionException: $message';
  }
}