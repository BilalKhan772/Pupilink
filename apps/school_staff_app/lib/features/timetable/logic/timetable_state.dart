class TimetableState {
  final bool isLoading;
  final bool isSaving;
  final List<Map<String, dynamic>> records;
  final String? error;
  final String? successMessage;
  final String selectedDay;

  const TimetableState({
    this.isLoading = false,
    this.isSaving = false,
    this.records = const [],
    this.error,
    this.successMessage,
    this.selectedDay = 'Monday',
  });

  TimetableState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Map<String, dynamic>>? records,
    String? error,
    String? successMessage,
    String? selectedDay,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TimetableState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      records: records ?? this.records,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  List<Map<String, dynamic>> get selectedDayRecords {
    final result = records.where((record) {
      return (record['day'] as String? ?? '') == selectedDay;
    }).toList();

    result.sort((a, b) {
      return (a['startTime'] as String? ?? '')
          .compareTo(b['startTime'] as String? ?? '');
    });

    return result;
  }
}