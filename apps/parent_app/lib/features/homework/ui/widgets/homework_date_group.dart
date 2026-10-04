import 'package:flutter/material.dart';

import 'homework_card.dart';

class HomeworkDateGroup
    extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> homework;
  final ValueChanged<Map<String, dynamic>>
      onHomeworkTap;

  const HomeworkDateGroup({
    super.key,
    required this.date,
    required this.homework,
    required this.onHomeworkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: Text(
            date.isEmpty
                ? 'Date not available'
                : date,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        ...homework.map(
          (item) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: HomeworkCard(
                homework: item,
                onTap: () {
                  onHomeworkTap(item);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}