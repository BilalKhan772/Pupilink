class PercentageCalculator {
  PercentageCalculator._();

  static double calculate(
    num obtained,
    num total,
  ) {
    if (total <= 0) {
      return 0;
    }

    return (obtained / total) * 100;
  }

  static double calculateFromCounts(
    int completed,
    int total,
  ) {
    if (total <= 0) {
      return 0;
    }

    return (completed / total) * 100;
  }

  static double clamp(double percentage) {
    if (percentage < 0) {
      return 0;
    }

    if (percentage > 100) {
      return 100;
    }

    return percentage;
  }

  static String format(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}