class ParentHomeworkState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;
  final String? error;
  final String selectedFilter;

  const ParentHomeworkState({
    this.isLoading = false,
    this.records = const [],
    this.error,
    this.selectedFilter = 'All',
  });

  ParentHomeworkState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    String? error,
    String? selectedFilter,
    bool clearError = false,
  }) {
    return ParentHomeworkState(
      isLoading:
          isLoading ?? this.isLoading,
      records:
          records ?? this.records,
      error: clearError
          ? null
          : (error ?? this.error),
      selectedFilter:
          selectedFilter ?? this.selectedFilter,
    );
  }

  List<Map<String, dynamic>> get filteredRecords {
    if (selectedFilter == 'All') {
      return records;
    }

    return records.where((record) {
      final status =
          record['status'] as String? ?? '';

      return status.toLowerCase() ==
          selectedFilter.toLowerCase();
    }).toList();
  }

  int get totalCount {
    return records.length;
  }

  int get pendingCount {
    return records.where((record) {
      return (record['status'] as String? ?? '')
              .toLowerCase() ==
          'pending';
    }).length;
  }

  int get completedCount {
    return records.where((record) {
      return (record['status'] as String? ?? '')
              .toLowerCase() ==
          'completed';
    }).length;
  }
}