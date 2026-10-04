class ParentTimetableState {
  final bool isLoading;
  final List<Map<String, dynamic>> records;
  final String? error;
  final String selectedDay;

  const ParentTimetableState({
    this.isLoading = false,
    this.records = const [],
    this.error,
    this.selectedDay = 'Monday',
  });

  ParentTimetableState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? records,
    String? error,
    String? selectedDay,
    bool clearError = false,
  }) {
    return ParentTimetableState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      error: clearError
          ? null
          : (error ?? this.error),
      selectedDay:
          selectedDay ?? this.selectedDay,
    );
  }

  List<Map<String, dynamic>> get selectedDayRecords {
    final filtered = records.where((record) {
      final day =
          record['day'] as String? ?? '';

      return day.toLowerCase() ==
          selectedDay.toLowerCase();
    }).toList();

    filtered.sort((a, b) {
      final timeA =
          a['startTime'] as String? ?? '';

      final timeB =
          b['startTime'] as String? ?? '';

      return timeA.compareTo(timeB);
    });

    return filtered;
  }

  Map<String, dynamic>? get currentPeriod {
    final periods = selectedDayRecords;

    if (periods.isEmpty) {
      return null;
    }

    return periods.first;
  }

  int get totalPeriods {
    return selectedDayRecords.length;
  }
}