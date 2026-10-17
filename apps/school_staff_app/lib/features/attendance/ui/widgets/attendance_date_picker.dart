
import 'package:flutter/material.dart';

class AttendanceDatePicker extends StatelessWidget {
  const AttendanceDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.enabled = true,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool enabled;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_month),
      label: Text(_formatDate(selectedDate)),
      onPressed: enabled
          ? () async {
              final now = DateTime.now();

              final initialDate = selectedDate.isAfter(now)
                  ? DateTime(now.year, now.month, now.day)
                  : selectedDate;

              final selected = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(now.year, now.month, now.day),
              );

              if (selected != null) {
                onDateChanged(selected);
              }
            }
          : null,
    );
  }
}
