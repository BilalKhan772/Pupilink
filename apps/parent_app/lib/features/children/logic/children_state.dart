
class ChildrenState {
  const ChildrenState({
    this.isLoading = false,
    this.isRemovingChild = false,
    this.removingLinkId,
    this.children = const [],
    this.error,
  });

  final bool isLoading;
  final bool isRemovingChild;
  final String? removingLinkId;
  final List<Map<String, dynamic>> children;
  final String? error;

  ChildrenState copyWith({
    bool? isLoading,
    bool? isRemovingChild,
    String? removingLinkId,
    bool clearRemovingLinkId = false,
    List<Map<String, dynamic>>? children,
    String? error,
    bool clearError = false,
  }) {
    return ChildrenState(
      isLoading: isLoading ?? this.isLoading,
      isRemovingChild: isRemovingChild ?? this.isRemovingChild,
      removingLinkId: clearRemovingLinkId
          ? null
          : removingLinkId ?? this.removingLinkId,
      children: children ?? this.children,
      error: clearError ? null : error ?? this.error,
    );
  }
}
