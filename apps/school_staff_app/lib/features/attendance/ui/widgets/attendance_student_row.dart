
import 'package:flutter/material.dart';

import 'attendance_status_selector.dart';

class AttendanceStudentRow extends StatelessWidget {
  const AttendanceStudentRow({
    super.key,
    required this.student,
    required this.status,
    required this.onStatusChanged,
    this.enabled = true,
  });

  final Map<String, dynamic> student;
  final String? status;
  final ValueChanged<String> onStatusChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unnamed Student';
    final admission = student['admissionNumber'] as String? ?? '';
    final photoUrl = student['photoUrl'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (admission.isNotEmpty)
                    Text(
                      admission,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: AttendanceStatusSelector(
                value: status,
                enabled: enabled,
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
