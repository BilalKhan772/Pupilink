import 'package:flutter/material.dart';

class CityDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const CityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> cities = [
    'Peshawar',
    'Islamabad',
    'Rawalpindi',
    'Lahore',
    'Karachi',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(),
      ),
      items: cities.map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}