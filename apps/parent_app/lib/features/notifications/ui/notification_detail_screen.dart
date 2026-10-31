
import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
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

    final schoolName = _string(
      notification['_displaySchoolName'],
    );

    final audienceLabel = _string(
      notification['_audienceLabel'],
    );

    final children = _displayChildren();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 24,
                vertical: 22,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(
                        context,
                        title,
                        type,
                      ),

                      const SizedBox(height: 22),

                      if (schoolName.isNotEmpty)
                        _buildInfoCard(
                          context: context,
                          icon: Icons.school_outlined,
                          title: 'School',
                          child: Text(
                            schoolName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      if (schoolName.isNotEmpty)
                        const SizedBox(height: 12),

                      _buildMessageCard(
                        context,
                        message,
                      ),

                      if (audienceLabel.isNotEmpty ||
                          children.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildRecipientCard(
                          context,
                          audienceLabel,
                          children,
                        ),
                      ],

                      const SizedBox(height: 14),

                      _buildInfoCard(
                        context: context,
                        icon: Icons.category_outlined,
                        title: 'Notification Type',
                        child: Text(
                          _getTypeLabel(type),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
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
    BuildContext context,
    String title,
    String type,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(type),
              size: 37,
              color: _darkGreen,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _getTypeLabel(type),
            style: const TextStyle(
              color: _darkGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable information card
  // ---------------------------------------------------------------------------

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 23,
            color: _green,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message card
  // ---------------------------------------------------------------------------

  Widget _buildMessageCard(
    BuildContext context,
    String message,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Text(
        message.isEmpty
            ? 'No message is available with this notification.'
            : message,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.65,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recipient information
  // ---------------------------------------------------------------------------

  Widget _buildRecipientCard(
    BuildContext context,
    String audienceLabel,
    List<Map<String, dynamic>> children,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 22,
                color: _green,
              ),
              const SizedBox(width: 12),
              Text(
                'Recipients',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          if (audienceLabel.isNotEmpty) ...[
            const SizedBox(height: 13),
            _buildRecipientTag(
              audienceLabel,
              Icons.public_outlined,
            ),
          ],

          if (children.isNotEmpty) ...[
            if (audienceLabel.isNotEmpty)
              const SizedBox(height: 14),
            ...children.map((child) {
              final label = _childLabel(child);

              if (label.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecipientTag(
                  label,
                  Icons.person_outline,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipientTag(
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _darkGreen,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: _darkGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification type
  // ---------------------------------------------------------------------------

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
