
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

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: statuses.containsKey(value) ? value : null,
      hint: const Text('Select status'),
      isExpanded: true,
      items: statuses.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: enabled
          ? (status) {
              if (status != null) onChanged(status);
            }
          : null,
    );
  }
}
