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
      final obtained =
          result['obtainedMarks'] as num? ?? 0;

      final total =
          result['totalMarks'] as num? ?? 0;

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
                padding:
                    const EdgeInsets.only(bottom: 12),
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

  Widget _resultCard(
    Map<String, dynamic> result,
  ) {
    final testName =
        result['testName'] as String? ??
            result['examName'] as String? ??
            'Test';

    final obtained =
        result['obtainedMarks'] as num? ?? 0;

    final total =
        result['totalMarks'] as num? ?? 0;

    final date =
        result['date'] as String? ?? '';

    final percentage = total == 0
        ? 0.0
        : (obtained / total) * 100;

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.assignment,
          ),
        ),
        title: Text(
          testName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${obtained.toInt()} / ${total.toInt()}'
          ' • '
          '${percentage.toStringAsFixed(1)}%'
          '${date.isEmpty ? '' : '\n$date'}',
        ),
      ),
    );
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
              'Is subject ke test results '
              'abhi available nahi hain.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateGrade(
    double percentage,
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