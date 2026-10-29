import 'package:flutter/material.dart';

class AttendanceStatusSelector extends StatelessWidget {
  const AttendanceStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const statuses = <String, String>{
    'present': 'Present',
    'absent': 'Absent',
    'late': 'Late',
    'leave': 'Leave',
  };

  static const Color _green = Color(0xFF138A4B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  Color _statusColor(String? status) {
    switch (status) {
      case 'present':
        return const Color(0xFF138A4B);
      case 'absent':
        return const Color(0xFFB42318);
      case 'late':
        return const Color(0xFFB7791F);
      case 'leave':
        return const Color(0xFF4F46A5);
      default:
        return _muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = statuses.containsKey(value) ? value : null;
    final accent = _statusColor(selected);

    // Keep the dropdown controlled by the selected status so it immediately
    // reflects updates made by the attendance controller.
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Attendance Status',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(Icons.fact_check_outlined, color: accent, size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF3F5F3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: const Text('Select status'),
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: statuses.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: enabled
              ? (status) {
                  if (status != null) onChanged(status);
                }
              : null,
        ),
      ),
    );
  }
}
