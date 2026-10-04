import 'package:flutter/material.dart';

class NotificationDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 35,
            child: Icon(
              _getIcon(type),
              size: 35,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.category,
              ),
              title: const Text(
                'Type',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _getTypeLabel(type),
              ),
            ),
          ),
        ],
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