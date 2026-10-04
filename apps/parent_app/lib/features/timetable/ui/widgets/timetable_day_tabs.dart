import 'package:flutter/material.dart';

class TimetableDayTabs extends StatelessWidget {
  final String selectedDay;
  final ValueChanged<String> onDaySelected;

  const TimetableDayTabs({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final isSelected =
              day == selectedDay;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (_) {
                onDaySelected(day);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}