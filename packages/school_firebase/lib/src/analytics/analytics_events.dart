
abstract final class AnalyticsEvents {
  AnalyticsEvents._();

  // Authentication
  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String logout = 'logout';

  // Parent App
  static const String childLinked = 'child_linked';
  static const String homeworkViewed = 'homework_viewed';
  static const String attendanceViewed = 'attendance_viewed';
  static const String resultViewed = 'result_viewed';
  static const String timetableViewed = 'timetable_viewed';

  // School Staff App
  static const String attendanceMarked = 'attendance_marked';
  static const String homeworkCreated = 'homework_created';
  static const String resultPublished = 'result_published';

  // General
  static const String screenViewed = 'screen_viewed';
  static const String notificationOpened = 'notification_opened';
  static const String errorOccurred = 'error_occurred';
}
