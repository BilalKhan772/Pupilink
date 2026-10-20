
import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const roles = <String, String>{
    'classTeacher': 'Class Teacher',
    'subjectTeacher': 'Subject Teacher',
    'monitor': 'Monitor',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: roles.containsKey(value) ? value : 'monitor',
      decoration: const InputDecoration(
        labelText: 'Staff Role',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      items: roles.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (role) {
              if (role != null) onChanged(role);
            }
          : null,
      validator: (role) =>
          role == null || !roles.containsKey(role) ? 'Role select karein.' : null,
    );
  }
}
