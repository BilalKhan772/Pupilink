import 'package:flutter/material.dart';

class TestResultDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> result;

  const TestResultDetailScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final subject =
        result['subject'] as String? ??
            'Subject';

    final obtainedMarks =
        result['obtainedMarks'] as num? ??
            0;

    final totalMarks =
        result['totalMarks'] as num? ??
            0;

    final percentage =
        totalMarks == 0
            ? 0
            : (obtainedMarks / totalMarks) *
                100;

    final grade =
        result['grade'] as String? ??
            _calculateGrade(percentage);

    final examName =
        result['examName'] as String? ??
            result['testName'] as String? ??
            'Test Result';

    final date =
        result['date'] as String? ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Result Details',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.assessment,
              size: 50,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              examName,
              style: TextStyle(
                fontSize: 16,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),

          const SizedBox(height: 25),

          _infoCard(
            'Obtained Marks',
            '${obtainedMarks.toInt()}',
          ),

          _infoCard(
            'Total Marks',
            '${totalMarks.toInt()}',
          ),

          _infoCard(
            'Percentage',
            '${percentage.toStringAsFixed(1)}%',
          ),

          _infoCard(
            'Grade',
            grade,
          ),

          if (date.isNotEmpty)
            _infoCard(
              'Date',
              date,
            ),

          const SizedBox(height: 20),

          const Text(
            'Result Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${obtainedMarks.toInt()} / '
                    '${totalMarks.toInt()}',
                    style:
                        const TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Grade: $grade',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value.isEmpty
              ? 'Not available'
              : value,
        ),
      ),
    );
  }

  String _calculateGrade(
    num percentage,
  ) {
    if (percentage >= 90) {
      return 'A+';
    }

    if (percentage >= 80) {
      return 'A';
    }

    if (percentage >= 70) {
      return 'B';
    }

    if (percentage >= 60) {
      return 'C';
    }

    if (percentage >= 50) {
      return 'D';
    }

    return 'F';
  }
}