import 'package:flutter/material.dart';

class HomeworkFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const HomeworkFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  static const List<String> filters = [
    'All',
    'Pending',
    'Completed',
  ];

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => onChanged(filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE2F2E7),
              side: BorderSide(
                color: selected ? const Color(0xFFB8DCC4) : _border,
              ),
              labelStyle: TextStyle(
                color: selected ? _darkGreen : const Color(0xFF68766E),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
