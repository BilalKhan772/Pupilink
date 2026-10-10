
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get navigationObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Analytics event name cannot be empty.',
      );
    }

    await _analytics.logEvent(
      name: normalizedName,
      parameters: parameters,
    );
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    final normalizedName = screenName.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        screenName,
        'screenName',
        'Screen name cannot be empty.',
      );
    }

    await _analytics.logScreenView(
      screenName: normalizedName,
      screenClass: screenClass,
    );
  }

  Future<void> setUserId(String? userId) {
    return _analytics.setUserId(
      id: userId?.trim().isEmpty == true ? null : userId?.trim(),
    );
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  Future<void> resetAnalyticsData() {
    return _analytics.resetAnalyticsData();
  }
}
