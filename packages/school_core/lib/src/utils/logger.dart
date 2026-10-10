class AppLogger {
  AppLogger._();

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message) {
    _log('WARNING', message);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message);

    if (error != null) {
      _log('ERROR', 'Exception: $error');
    }

    if (stackTrace != null) {
      _log('ERROR', stackTrace.toString());
    }
  }

  static void debug(String message) {
    _log('DEBUG', message);
  }

  static void _log(
    String level,
    String message,
  ) {
    // ignore: avoid_print
    print('[$level] $message');
  }
}