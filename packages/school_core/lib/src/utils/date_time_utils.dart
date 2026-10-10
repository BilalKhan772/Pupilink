class DateTimeUtils {
  DateTimeUtils._();

  static DateTime startOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    );
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      1,
    );
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(
      date.year,
      date.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
  }

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return isSameDay(date, yesterday);
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(
      const Duration(days: 1),
    );

    return isSameDay(date, tomorrow);
  }

  static String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  static String formatTime(DateTime date) {
    return '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }
}