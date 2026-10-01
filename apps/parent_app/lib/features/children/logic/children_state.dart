class ChildrenState {
  final bool isLoading;
  final List<Map<String, dynamic>> children;
  final String? error;

  const ChildrenState({
    this.isLoading = false,
    this.children = const [],
    this.error,
  });

  ChildrenState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? children,
    String? error,
    bool clearError = false,
  }) {
    return ChildrenState(
      isLoading:
          isLoading ?? this.isLoading,
      children:
          children ?? this.children,
      error: clearError
          ? null
          : (error ?? this.error),
    );
  }
}