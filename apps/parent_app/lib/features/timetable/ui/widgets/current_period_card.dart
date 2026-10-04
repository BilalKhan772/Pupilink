import 'package:flutter/material.dart';

class CurrentPeriodCard extends StatelessWidget {
  final Map<String, dynamic>? period;

  const CurrentPeriodCard({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (period == null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 32,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Period',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Abhi koi period available nahi hai.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final subject =
        period!['subject'] as String? ??
            'Subject';

    final teacher =
        period!['teacher'] as String? ??
            '';

    final room =
        period!['room'] as String? ??
            '';

    final startTime =
        period!['startTime'] as String? ??
            '';

    final endTime =
        period!['endTime'] as String? ??
            '';

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.access_time,
                ),
                SizedBox(width: 8),
                Text(
                  'Current Period',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              subject,
              style: const TextStyle(
                fontSize: 22,
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

            if (startTime.isNotEmpty ||
                endTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  color:
                      Colors.grey.shade700,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}