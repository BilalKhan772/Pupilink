
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  static const Color _green = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFE9F6EE);

  String _string(dynamic value) {
    return value is String ? value.trim() : '';
  }

  List<Map<String, dynamic>> _displayChildren() {
    final value = notification['_displayChildren'];

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }

  String _childLabel(Map<String, dynamic> child) {
    final name = _string(
      child['name'] ?? child['studentName'],
    );

    final className = _string(child['className']);
    final section = _string(child['section']);

    final classParts = <String>[];

    if (className.isNotEmpty) {
      classParts.add(
        className.toLowerCase().startsWith('class')
            ? className
            : 'Class $className',
      );
    }

    if (section.isNotEmpty) {
      classParts.add(section);
    }

    final classLabel = classParts.join('-');

    if (name.isEmpty) return classLabel;
    if (classLabel.isEmpty) return name;

    return '$name · $classLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = _string(notification['title']).isEmpty
        ? 'Notification'
        : _string(notification['title']);

    final message = _string(notification['body']).isNotEmpty
        ? _string(notification['body'])
        : _string(notification['message']);

    final type = _getNotificationType();
    final isRead = notification['isRead'] == true;

    final schoolName = _string(
      notification['_displaySchoolName'],
    );

    final audienceLabel = _string(
      notification['_audienceLabel'],
    );

    final children = _displayChildren();

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(type),
                    color: _darkGreen,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: _green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (schoolName.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 15,
                              color: _green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                schoolName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _darkGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.72),
                            height: 1.45,
                          ),
                        ),
                      ],

                      if (audienceLabel.isNotEmpty ||
                          children.isNotEmpty) ...[
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (audienceLabel.isNotEmpty)
                              _buildTag(
                                label: audienceLabel,
                                icon: audienceLabel == 'All School'
                                    ? Icons.public_outlined
                                    : Icons.school_outlined,
                              ),
                            ...children.map((child) {
                              final label = _childLabel(child);

                              if (label.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return _buildTag(
                                label: label,
                                icon: Icons.person_outline,
                              );
                            }),
                          ],
                        ),
                      ],

                      const SizedBox(height: 11),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTypeLabel(type),
                          style: const TextStyle(
                            color: _darkGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.iconTheme.color?.withOpacity(0.55),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _lightGreen.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _green.withOpacity(0.13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 0),
          Icon(
            icon,
            size: 14,
            color: _darkGreen,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getNotificationType() {
    final directType = _string(notification['type']);

    if (directType.isNotEmpty &&
        directType.toLowerCase() != 'notification' &&
        directType.toLowerCase() != 'general') {
      return directType.toLowerCase();
    }

    final rawData = notification['data'];

    if (rawData is Map) {
      final dataType = rawData['notificationType'];

      if (dataType is String && dataType.trim().isNotEmpty) {
        return dataType.trim().toLowerCase();
      }
    }

    return 'general';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'homework':
        return Icons.menu_book_outlined;
      case 'attendance':
        return Icons.fact_check_outlined;
      case 'result':
      case 'results':
        return Icons.assessment_outlined;
      case 'timetable':
        return Icons.calendar_month_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'test_reminder':
        return Icons.quiz_outlined;
      case 'date_sheet':
        return Icons.event_note_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

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
