class UpcomingTestsState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;
  final String? error;

  const UpcomingTestsState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  UpcomingTestsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    String? error,
    bool clearError = false,
  }) {
    return UpcomingTestsState(
      isLoading:
          isLoading ?? this.isLoading,
      records:
          records ?? this.records,
      error: clearError
          ? null
          : (error ?? this.error),
    );
  }

  int get totalTests {
    return records.length;
  }

  bool get hasTests {
    return records.isNotEmpty;
  }

  bool get hasNoTests {
    return records.isEmpty;
  }

  Map<String, dynamic>? get nextTest {
    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }
}