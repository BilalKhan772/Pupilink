
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

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _avatar(String name, String? photoUrl) {
    final validUrl = photoUrl != null && photoUrl.trim().isNotEmpty;

    if (!validUrl) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE4F3E9),
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: _darkGreen,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE4F3E9),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            width: 44,
            height: 44,
            color: const Color(0xFFEAF6EF),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _green,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unnamed Student';
    final admission =
        student['admissionNumber'] as String? ?? '';
    final photoUrl = student['photoUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final studentInfo = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (admission.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    admission,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(13),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _avatar(name, photoUrl),
                          const SizedBox(width: 12),
                          studentInfo,
                        ],
                      ),
                      const SizedBox(height: 12),

                      // The selector itself displays "Attendance Status".
                      // The extra mobile-only heading has been removed
                      // to prevent the label appearing twice.
                      AttendanceStatusSelector(
                        value: status,
                        enabled: enabled,
                        onChanged: onStatusChanged,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _avatar(name, photoUrl),
                      const SizedBox(width: 13),
                      studentInfo,
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 230,
                        child: AttendanceStatusSelector(
                          value: status,
                          enabled: enabled,
                          onChanged: onStatusChanged,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
