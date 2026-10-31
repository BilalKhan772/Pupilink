
import 'package:flutter/material.dart';

class AdmissionNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const AdmissionNumberField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  static const Color _green = Color(0xFF138A4B);
  static const Color _border = Color(0xFFDCE9DF);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: 'e.g. STU-1001',
        prefixIcon: const Icon(
          Icons.badge_outlined,
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
      validator: (value) {
        final admissionNumber = value?.trim() ?? '';

        if (admissionNumber.isEmpty) {
          return 'Please enter the admission number.';
        }

        if (admissionNumber.length > 64) {
          return 'Admission number is too long.';
        }

        return null;
      },
    );
  }
}
