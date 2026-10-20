
import 'package:flutter/material.dart';

import 'homework_card.dart';

class HomeworkDateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> homework;
  final ValueChanged<Map<String, dynamic>> onHomeworkTap;

  const HomeworkDateGroup({
    super.key,
    required this.date,
    required this.homework,
    required this.onHomeworkTap,
  });

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value.isEmpty ? 'Date not available' : value;

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...homework.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HomeworkCard(
              homework: item,
              onTap: () => onHomeworkTap(item),
            ),
          ),
        ),
      ],
    );
  }
}
