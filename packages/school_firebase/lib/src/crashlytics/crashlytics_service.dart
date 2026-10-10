
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  Future<void> recordFlutterFatalError(
    FlutterErrorDetails details,
  ) {
    return _crashlytics.recordFlutterFatalError(details);
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details,
  ) {
    return _crashlytics.recordFlutterError(details);
  }

  Future<void> log(String message) {
    return _crashlytics.log(message);
  }

  Future<void> setUserIdentifier(String identifier) {
    return _crashlytics.setUserIdentifier(identifier);
  }

  Future<void> setCustomKey(String key, Object value) {
    return _crashlytics.setCustomKey(key, value);
  }
}
