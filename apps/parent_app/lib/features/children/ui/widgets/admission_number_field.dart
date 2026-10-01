import 'package:flutter/material.dart';

class AdmissionNumberField extends StatelessWidget {
  final TextEditingController controller;

  const AdmissionNumberField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization:
          TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Admission Number',
        hintText: 'Example: STU-1001',
        border: OutlineInputBorder(),
      ),
    );
  }
}