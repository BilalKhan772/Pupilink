
import 'package:flutter/material.dart';

class CityDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  const CityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  static const Color _green = Color(0xFF138A4B);
  static const Color _border = Color(0xFFDCE9DF);

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
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select City',
        prefixIcon: const Icon(
          Icons.location_city_outlined,
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
      items: cities.map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
      }).toList(),
      validator: validator ??
          (selected) {
            if (selected == null || selected.isEmpty) {
              return 'Please select a city.';
            }
            return null;
          },
      onChanged: enabled ? onChanged : null,
    );
  }
}
