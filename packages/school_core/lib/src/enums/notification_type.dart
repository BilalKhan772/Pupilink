enum NotificationType {
  general,
  homework,
  attendance,
  result,
  testReminder,
  dateSheet,
  announcement,
  message,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.general:
        return 'general';
      case NotificationType.homework:
        return 'homework';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.result:
        return 'result';
      case NotificationType.testReminder:
        return 'testReminder';
      case NotificationType.dateSheet:
        return 'dateSheet';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.message:
        return 'message';
    }
  }
}