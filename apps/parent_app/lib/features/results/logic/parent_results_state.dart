class ParentResultsState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;
  final String? error;

  const ParentResultsState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  ParentResultsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    String? error,
    bool clearError = false,
  }) {
    return ParentResultsState(
      isLoading:
          isLoading ?? this.isLoading,
      records:
          records ?? this.records,
      error: clearError
          ? null
          : (error ?? this.error),
    );
  }

  int get totalSubjects {
    return records.length;
  }

  int get totalObtainedMarks {
    return records.fold(
      0,
      (total, record) {
        final marks =
            record['obtainedMarks'];

        if (marks is num) {
          return total + marks.toInt();
        }

        return total;
      },
    );
  }

  int get totalPossibleMarks {
    return records.fold(
      0,
      (total, record) {
        final marks =
            record['totalMarks'];

        if (marks is num) {
          return total + marks.toInt();
        }

        return total;
      },
    );
  }

  double get percentage {
    if (totalPossibleMarks == 0) {
      return 0;
    }

    return (totalObtainedMarks /
            totalPossibleMarks) *
        100;
  }

  String get grade {
    final value = percentage;

    if (value >= 90) {
      return 'A+';
    }

    if (value >= 80) {
      return 'A';
    }

    if (value >= 70) {
      return 'B';
    }

    if (value >= 60) {
      return 'C';
    }

    if (value >= 50) {
      return 'D';
    }

    return 'F';
  }
}