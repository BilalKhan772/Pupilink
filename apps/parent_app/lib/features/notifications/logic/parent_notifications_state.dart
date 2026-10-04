class ParentNotificationsState {
  final bool isLoading;
  final List<Map<String, dynamic>> notifications;
  final String? error;

  const ParentNotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  ParentNotificationsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? notifications,
    String? error,
    bool clearError = false,
  }) {
    return ParentNotificationsState(
      isLoading:
          isLoading ?? this.isLoading,
      notifications:
          notifications ?? this.notifications,
      error: clearError
          ? null
          : (error ?? this.error),
    );
  }

  int get totalCount {
    return notifications.length;
  }

  int get unreadCount {
    return notifications.where((notification) {
      return notification['isRead'] != true;
    }).length;
  }

  int get readCount {
    return notifications.where((notification) {
      return notification['isRead'] == true;
    }).length;
  }

  bool get hasNotifications {
    return notifications.isNotEmpty;
  }

  bool get hasUnreadNotifications {
    return unreadCount > 0;
  }
}