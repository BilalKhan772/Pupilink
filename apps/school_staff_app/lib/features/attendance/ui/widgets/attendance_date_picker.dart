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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _muted = Color(0xFF68766E);

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final initialDate = selectedDay.isAfter(today) ? today : selectedDay;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkGreen,
        backgroundColor: enabled ? Colors.white : const Color(0xFFF3F5F3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: enabled
          ? () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2020),
                lastDate: today,
                helpText: 'Select Attendance Date',
                cancelText: 'Cancel',
                confirmText: 'Select Date',
              );

              if (selected != null) {
                onDateChanged(DateTime(selected.year, selected.month, selected.day));
              }
            }
          : null,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: _green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Date',
                  style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(color: _darkGreen, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_calendar_outlined, color: _muted, size: 20),
        ],
      ),
    );
  }
}
