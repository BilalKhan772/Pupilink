import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        notification['title'] as String? ??
            'Notification';

    final message =
        notification['message'] as String? ??
            '';

    final type = _getNotificationType();

    final isRead =
        notification['isRead'] == true;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(
                  _getIcon(type),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin:
                                const EdgeInsets.only(
                              top: 5,
                              left: 8,
                            ),
                            decoration:
                                const BoxDecoration(
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _getTypeLabel(type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------
  // Get notification type
  // --------------------------------
  String _getNotificationType() {
    final directType =
        notification['type'] as String? ??
            '';

    if (directType.trim().isNotEmpty &&
        directType.toLowerCase() !=
            'notification' &&
        directType.toLowerCase() !=
            'general') {
      return directType
          .trim()
          .toLowerCase();
    }

    final rawData =
        notification['data'];

    if (rawData is Map) {
      final dataType =
          rawData['notificationType'];

      if (dataType is String &&
          dataType.trim().isNotEmpty) {
        return dataType
            .trim()
            .toLowerCase();
      }
    }

    return 'general';
  }

  // --------------------------------
  // Notification icon
  // --------------------------------
  IconData _getIcon(String type) {
    switch (type) {
      case 'homework':
        return Icons.menu_book;

      case 'attendance':
        return Icons.fact_check;

      case 'result':
      case 'results':
        return Icons.assessment;

      case 'timetable':
        return Icons.calendar_month;

      case 'announcement':
        return Icons.campaign;

      case 'test_reminder':
        return Icons.quiz;

      case 'date_sheet':
        return Icons.calendar_month;

      default:
        return Icons.notifications;
    }
  }

  // --------------------------------
  // Notification type label
  // --------------------------------
  String _getTypeLabel(String type) {
    switch (type) {
      case 'homework':
        return 'Homework';

      case 'attendance':
        return 'Attendance';

      case 'result':
      case 'results':
        return 'Result';

      case 'timetable':
        return 'Timetable';

      case 'announcement':
        return 'Announcement';

      case 'test_reminder':
        return 'Test Reminder';

      case 'date_sheet':
        return 'Date Sheet';

      default:
        return 'Notification';
    }
  }
}