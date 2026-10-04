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

    final type =
        notification['type'] as String? ??
            'general';

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
          padding: const EdgeInsets.all(16),
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

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
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

      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
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

      default:
        return 'Notification';
    }
  }
}