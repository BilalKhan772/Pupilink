extension NumExtension on num {
  double get percentage {
    if (this < 0) {
      return 0;
    }

    if (this > 100) {
      return 100;
    }

    return toDouble();
  }

  String get percentageText {
    return '${percentage.toStringAsFixed(1)}%';
  }

  bool get isPositive => this > 0;

  bool get isNegative => this < 0;

  bool get isZero => this == 0;

  bool get isWholeNumber => this % 1 == 0;
}