
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_notifications_controller.dart';
import '../logic/parent_notifications_state.dart';
import 'notification_detail_screen.dart';
import 'widgets/notification_tile.dart';

class ParentNotificationsScreen extends ConsumerStatefulWidget {
  const ParentNotificationsScreen({
    super.key,
  });

  @override
  ConsumerState<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<ParentNotificationsScreen> {
  static const Color _green = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFE9F6EE);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      ref
          .read(parentNotificationsControllerProvider.notifier)
          .loadNotifications();
    });
  }

  // ---------------------------------------------------------------------------
  // Open notification
  // ---------------------------------------------------------------------------

  Future<void> _openNotification(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id'] as String? ?? '';

    Map<String, dynamic> detailNotification = {
      ...notification,
    };

    if (notificationId.isNotEmpty &&
        notification['isRead'] != true) {
      final success = await ref
          .read(parentNotificationsControllerProvider.notifier)
          .markAsRead(notificationId: notificationId);

      if (success) {
        detailNotification['isRead'] = true;
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(
          notification: detailNotification,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  Future<void> _refresh() async {
    await ref
        .read(parentNotificationsControllerProvider.notifier)
        .refresh();
  }

  // ---------------------------------------------------------------------------
  // Main screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      parentNotificationsControllerProvider,
    );

    final theme = Theme.of(context);

    final isInitialLoading =
        state.isLoading && state.notifications.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _green,
              ),
            )
          : RefreshIndicator(
              color: _green,
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 24,
                      vertical: 20,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1100,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(state),

                              if (state.isLoading) ...[
                                const SizedBox(height: 14),
                                const LinearProgressIndicator(
                                  color: _green,
                                  minHeight: 2,
                                ),
                              ],

                              if (state.error != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorCard(
                                  state.error!,
                                ),
                              ],

                              const SizedBox(height: 20),

                              if (state.notifications.isEmpty)
                                _buildEmptyNotifications(
                                  hasError: state.error != null,
                                )
                              else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Recent Notifications',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${state.totalCount} total',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.textTheme.bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 13),

                                ...state.notifications.map(
                                  (notification) {
                                    return NotificationTile(
                                      notification: notification,
                                      onTap: () {
                                        _openNotification(notification);
                                      },
                                    );
                                  },
                                ),
                              ],

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    ParentNotificationsState state,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: _darkGreen,
              size: 29,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  state.hasUnreadNotifications
                      ? '${state.unreadCount} unread notification'
                          '${state.unreadCount == 1 ? '' : 's'}'
                      : 'You are all caught up. No unread notifications.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error card
  // ---------------------------------------------------------------------------

  Widget _buildErrorCard(String message) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyNotifications({
    required bool hasError,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 43,
              color: _darkGreen,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            hasError
                ? 'Notifications Unavailable'
                : 'No Notifications Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            hasError
                ? 'We could not retrieve your notifications. Please try again.'
                : 'You will see school announcements, homework updates, '
                    'and other important information here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color
                  ?.withOpacity(0.7),
              height: 1.5,
            ),
          ),

          if (hasError) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  Color _cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }
}
