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

  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _muted = Color(0xFF68766E);
  static const Color _border = Color(0xFFDDE9E1);

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.trim().isEmpty ? 'Date not available' : value;
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} '
        '${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: _darkGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: _darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${homework.length} ${homework.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // One shared card per due date; all homework for this date
        // is displayed as rows inside this single container.
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163B28).withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: List.generate(homework.length, (index) {
                  final item = homework[index];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HomeworkCard(
                        homework: item,
                        onTap: () => onHomeworkTap(item),
                      ),
                      if (index < homework.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 17,
                          endIndent: 17,
                          color: _border,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
