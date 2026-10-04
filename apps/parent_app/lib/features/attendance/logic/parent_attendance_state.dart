class ParentAttendanceState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;
  final String? error;

  const ParentAttendanceState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  ParentAttendanceState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    String? error,
    bool clearError = false,
  }) {
    return ParentAttendanceState(
      isLoading:
          isLoading ?? this.isLoading,
      records:
          records ?? this.records,
      error: clearError
          ? null
          : (error ?? this.error),
    );
  }

  int get presentCount {
    return records.where((record) {
      return record['status'] == 'present';
    }).length;
  }

  int get absentCount {
    return records.where((record) {
      return record['status'] == 'absent';
    }).length;
  }

  int get lateCount {
    return records.where((record) {
      return record['status'] == 'late';
    }).length;
  }

  int get totalCount {
    return records.length;
  }

  double get attendancePercentage {
    if (totalCount == 0) {
      return 0;
    }

    return ((presentCount + lateCount) /
            totalCount) *
        100;
  }
}