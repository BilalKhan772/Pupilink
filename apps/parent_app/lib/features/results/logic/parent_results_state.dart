
class ParentResultsState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;

  // Permanent subject averages from subjectAverages collection.
  final List<Map<String, dynamic>> subjectAverages;

  // Permanent overall average from studentAverages collection.
  final Map<String, dynamic>? studentAverage;

  final String? error;

  const ParentResultsState({
    this.isLoading = false,
    this.records = const [],
    this.subjectAverages = const [],
    this.studentAverage,
    this.error,
  });

  ParentResultsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    List<Map<String, dynamic>>? subjectAverages,
    Map<String, dynamic>? studentAverage,
    bool clearStudentAverage = false,
    String? error,
    bool clearError = false,
  }) {
    return ParentResultsState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      subjectAverages: subjectAverages ?? this.subjectAverages,
      studentAverage: clearStudentAverage
          ? null
          : (studentAverage ?? this.studentAverage),
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Overall values use the permanent average whenever available.
  int get totalObtainedMarks {
    final value = studentAverage?['totalObtainedMarks'];

    if (value is num) return value.toInt();

    return records.fold<int>(0, (total, record) {
      final marks = record['obtainedMarks'];
      return total + (marks is num ? marks.toInt() : 0);
    });
  }

  int get totalPossibleMarks {
    final value = studentAverage?['totalPossibleMarks'];

    if (value is num) return value.toInt();

    return records.fold<int>(0, (total, record) {
      final marks = record['totalMarks'];
      return total + (marks is num ? marks.toInt() : 0);
    });
  }

  double get percentage {
    final savedPercentage = studentAverage?['percentage'];

    if (savedPercentage is num) {
      return savedPercentage.toDouble();
    }

    if (totalPossibleMarks == 0) return 0;

    return (totalObtainedMarks / totalPossibleMarks) * 100;
  }

  String get grade {
    final savedGrade = studentAverage?['grade'];

    if (savedGrade is String && savedGrade.isNotEmpty) {
      return savedGrade;
    }

    final value = percentage;

    if (value >= 90) return 'A+';
    if (value >= 80) return 'A';
    if (value >= 70) return 'B';
    if (value >= 60) return 'C';
    if (value >= 50) return 'D';

    return 'F';
  }

  int get totalSubjects {
    if (subjectAverages.isNotEmpty) {
      return subjectAverages.length;
    }

    return records
        .map((record) => record['subjectId'] ?? record['subject'] ?? 'Subject')
        .toSet()
        .length;
  }
}
