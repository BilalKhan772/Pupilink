
import 'package:flutter/material.dart';

class SchoolDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  const SchoolDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  static const Color _green = Color(0xFF138A4B);
  static const Color _border = Color(0xFFDCE9DF);

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
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select School',
        prefixIcon: const Icon(
          Icons.school_outlined,
          color: _green,
          size: 21,
        ),
        filled: true,
        fillColor: const Color(0xFFFCFEFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: _green,
            width: 1.5,
          ),
        ),
      ),
      items: schools.map((school) {
        return DropdownMenuItem<String>(
          value: school['id'],
          child: Text(
            school['name']!,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: validator ??
          (selected) {
            if (selected == null || selected.isEmpty) {
              return 'Please select a school.';
            }
            return null;
          },
      onChanged: enabled ? onChanged : null,
    );
  }
}
