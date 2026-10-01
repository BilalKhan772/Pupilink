import 'package:flutter/material.dart';

class SchoolDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const SchoolDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<Map<String, String>> schools = [
    {
      'id': 'school_001',
      'name': 'Demo School Peshawar',
    },
    {
      'id': 'school_002',
      'name': 'Demo School Islamabad',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'School',
        border: OutlineInputBorder(),
      ),
      items: schools.map((school) {
        return DropdownMenuItem<String>(
          value: school['id'],
          child: Text(school['name']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}