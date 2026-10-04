import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_notifications_controller.dart';
import '../logic/parent_notifications_state.dart';
import 'notification_detail_screen.dart';
import 'widgets/notification_tile.dart';

class ParentNotificationsScreen
    extends ConsumerStatefulWidget {
  const ParentNotificationsScreen({
    super.key,
  });

  @override
  ConsumerState<
      ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<
        ParentNotificationsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(
            parentNotificationsControllerProvider
                .notifier,
          )
          .loadNotifications();
    });
  }

  Future<void> _openNotification(
    Map<String, dynamic> notification,
  ) async {
    final notificationId =
        notification['id'] as String? ?? '';

    if (notificationId.isNotEmpty &&
        notification['isRead'] != true) {
      await ref
          .read(
            parentNotificationsControllerProvider
                .notifier,
          )
          .markAsRead(
            notificationId:
                notificationId,
          );
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationDetailScreen(
          notification: notification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      parentNotificationsControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(
                      parentNotificationsControllerProvider
                          .notifier,
                    )
                    .refresh();
              },
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  _buildHeader(state),

                  const SizedBox(height: 20),

                  if (state.error != null)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child: Text(
                          state.error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  if (state.notifications.isEmpty)
                    _emptyNotifications()
                  else
                    ...state.notifications.map(
                      (notification) {
                        return NotificationTile(
                          notification:
                              notification,
                          onTap: () {
                            _openNotification(
                              notification,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(
    ParentNotificationsState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.notifications,
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    state.hasUnreadNotifications
                        ? '${state.unreadCount} unread notification'
                          '${state.unreadCount == 1 ? '' : 's'}'
                        : 'No unread notifications',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyNotifications() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(35),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 70,
            ),

            SizedBox(height: 15),

            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Abhi aapke liye koi notification available nahi hai.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}