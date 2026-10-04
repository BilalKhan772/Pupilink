import 'package:flutter/material.dart';

class TimetablePeriodCard extends StatelessWidget {
  final Map<String, dynamic> period;

  const TimetablePeriodCard({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final subject =
        period['subject'] as String? ??
            'Subject';

    final teacher =
        period['teacher'] as String? ??
            '';

    final room =
        period['room'] as String? ??
            '';

    final startTime =
        period['startTime'] as String? ??
            '';

    final endTime =
        period['endTime'] as String? ??
            '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(
                Icons.menu_book,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (teacher.isNotEmpty)
                    Text(
                      'Teacher: $teacher',
                    ),

                  if (room.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Room: $room',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  startTime.isEmpty
                      ? '--'
                      : startTime,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  endTime.isEmpty
                      ? '--'
                      : endTime,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}