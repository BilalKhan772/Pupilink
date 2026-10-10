import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    required this.controller,
    required this.onTimeSelected,
    this.label = 'Select time',
    this.initialTime,
  });

  final TextEditingController controller;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final String label;
  final TimeOfDay? initialTime;

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (selected == null || !context.mounted) return;

    controller.text = selected.format(context);
    onTimeSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
