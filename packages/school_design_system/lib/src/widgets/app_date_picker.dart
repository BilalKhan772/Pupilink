
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.controller,
    required this.onDateSelected,
    this.label = 'Select date',
    this.firstDate,
    this.lastDate,
    this.initialDate,
  });

  final TextEditingController controller;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    var initial = initialDate ?? now;

    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (selected == null) return;

    controller.text =
        '${selected.day.toString().padLeft(2, '0')}/'
        '${selected.month.toString().padLeft(2, '0')}/'
        '${selected.year}';

    onDateSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
