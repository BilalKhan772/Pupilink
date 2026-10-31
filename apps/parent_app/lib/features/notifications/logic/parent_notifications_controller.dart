
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_notifications_repository.dart';
import 'parent_notifications_state.dart';

final parentNotificationsRepositoryProvider =
    Provider<ParentNotificationsRepository>((ref) {
  return ParentNotificationsRepository();
});

final parentNotificationsControllerProvider =
    StateNotifierProvider<
        ParentNotificationsController,
        ParentNotificationsState>(
  (ref) {
    return ParentNotificationsController(
      ref.read(parentNotificationsRepositoryProvider),
    );
  },
);

class ParentNotificationsController
    extends StateNotifier<ParentNotificationsState> {
  final ParentNotificationsRepository repository;

  ParentNotificationsController(this.repository)
      : super(const ParentNotificationsState());

  Future<void> loadNotifications() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final notifications = await repository.getNotifications();

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load notifications. Please try again.',
      );
    }
  }

  Future<bool> markAsRead({
    required String notificationId,
  }) async {
    try {
      await repository.markAsRead(
        notificationId: notificationId,
      );

      final updatedNotifications =
          state.notifications.map((notification) {
        if (notification['id'] == notificationId) {
          return {
            ...notification,
            'isRead': true,
          };
        }

        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Unable to mark notification as read.',
      );

      return false;
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}
