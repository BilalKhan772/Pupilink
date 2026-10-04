import 'package:flutter/material.dart';

class HomeworkFilterBar
    extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected =
              selectedFilter == filter;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                onChanged(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}