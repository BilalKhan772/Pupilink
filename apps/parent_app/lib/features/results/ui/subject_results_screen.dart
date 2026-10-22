
import 'package:flutter/material.dart';

class SubjectResultsScreen extends StatelessWidget {
  final String subject;
  final List<Map<String, dynamic>> results;

  const SubjectResultsScreen({
    super.key,
    required this.subject,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    int totalObtained = 0;
    int totalMarks = 0;

    for (final result in results) {
      final obtained = result['obtainedMarks'] as num? ?? 0;
      final total = result['totalMarks'] as num? ?? 0;

      totalObtained += obtained.toInt();
      totalMarks += total.toInt();
    }

    final percentage = totalMarks == 0
        ? 0.0
        : (totalObtained / totalMarks) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _summaryCard(
            totalObtained: totalObtained,
            totalMarks: totalMarks,
            percentage: percentage,
          ),
          const SizedBox(height: 25),
          const Text(
            'Test Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            _emptyResults()
          else
            ...results.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _resultCard(result),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int totalObtained,
    required int totalMarks,
    required double percentage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Subject Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '$totalObtained / $totalMarks',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grade: ${_calculateGrade(percentage)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final testName =
        result['testName'] as String? ??
        result['examName'] as String? ??
        'Test';

    final obtained = result['obtainedMarks'] as num? ?? 0;
    final total = result['totalMarks'] as num? ?? 0;

    final rawDate = result['date'];
    final formattedDate = _formatDate(rawDate);

    final percentage =
        total == 0 ? 0.0 : (obtained / total) * 100;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: const CircleAvatar(
          child: Icon(Icons.assignment),
        ),
        title: Text(
          testName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${obtained.toInt()} / ${total.toInt()}'
                ' • ${percentage.toStringAsFixed(1)}%',
              ),
              if (formattedDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    DateTime? dateTime;

    if (value is DateTime) {
      dateTime = value;
    } else if (value is String) {
      dateTime = DateTime.tryParse(value);
    } else if (value is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (dateTime == null) return '';

    // Device ki local timezone mein date show hogi.
    final localDate = dateTime.toLocal();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;

    return '$day $month $year';
  }

  Widget _emptyResults() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(
              Icons.assignment,
              size: 60,
            ),
            SizedBox(height: 12),
            Text(
              'No Test Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Is subject ke test results abhi available nahi hain.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
