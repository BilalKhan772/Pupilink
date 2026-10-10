extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year &&
        month == other.month &&
        day == other.day;
  }

  bool get isToday {
    final now = DateTime.now();

    return isSameDay(now);
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return isSameDay(yesterday);
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(
      const Duration(days: 1),
    );

    return isSameDay(tomorrow);
  }

  DateTime get startOfDay {
    return DateTime(
      year,
      month,
      day,
    );
  }

  DateTime get endOfDay {
    return DateTime(
      year,
      month,
      day,
      23,
      59,
      59,
      999,
    );
  }

  String get yyyyMmDd {
    final monthString = month.toString().padLeft(2, '0');
    final dayString = day.toString().padLeft(2, '0');

    return '$year-$monthString-$dayString';
  }
}