import 'package:flutter/material.dart';

class SubjectResultsScreen extends StatelessWidget {
  final String subject;
  final List<Map<String, dynamic>> results;

  /// Combined all-time average supplied by TestResultsScreen.
  /// Optional to preserve compatibility with existing callers.
  final Map<String, dynamic>? averageSummary;

  const SubjectResultsScreen({
    super.key,
    required this.subject,
    required this.results,
    this.averageSummary,
  });

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  double _number(dynamic value) {
    return value is num ? value.toDouble() : 0.0;
  }

  String _formatMarks(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed == null) return '';

    final date = parsed.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }

  String _grade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    // Use the combined permanent average when supplied.
    // Fall back to currently available individual results for old callers.
    double totalObtained = 0;
    double totalMarks = 0;
    int testCount = results.length;

    if (averageSummary != null) {
      totalObtained = _number(averageSummary!['obtainedMarks']);
      totalMarks = _number(averageSummary!['totalMarks']);

      final savedCount = averageSummary!['testCount'];
      if (savedCount is num) {
        testCount = savedCount.toInt();
      }
    } else {
      for (final result in results) {
        totalObtained += _number(result['obtainedMarks']);
        totalMarks += _number(result['totalMarks']);
      }
    }

    final percentage = totalMarks > 0
        ? (totalObtained / totalMarks) * 100
        : 0.0;

    final progress =
        (percentage / 100).clamp(0.0, 1.0).toDouble();

    final orderedResults = List<Map<String, dynamic>>.from(results)
      ..sort((a, b) {
        final dateA = _parseDate(a['date']);
        final dateB = _parseDate(b['date']);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(subject),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth < 600 ? 16.0 : 24.0;

          final contentWidth = constraints.maxWidth >= 1100
              ? 980.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  36,
                ),
                children: [
                  _summaryCard(
                    totalObtained: totalObtained,
                    totalMarks: totalMarks,
                    percentage: percentage,
                    progress: progress,
                    testCount: testCount,
                  ),
                  const SizedBox(height: 26),
                  _sectionHeader(
                    title: 'Test Results',
                    subtitle:
                        'Individual tests currently available to view',
                    count: orderedResults.length,
                  ),
                  const SizedBox(height: 12),
                  if (orderedResults.isEmpty)
                    const _EmptySubjectResults()
                  else
                    ...orderedResults.map(
                      (result) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _resultCard(result),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required double totalObtained,
    required double totalMarks,
    required double percentage,
    required double progress,
    required int testCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE4F3E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _darkGreen,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Subject Summary',
            style: TextStyle(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_formatMarks(totalObtained)} / ${_formatMarks(totalMarks)}',
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: _green,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grade: ${_grade(percentage)}',
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _green,
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Based on all published marks. Expired individual tests remain included in this average.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$testCount ${testCount == 1 ? 'test' : 'tests'} counted in the subject average',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final testName = result['testName'] as String? ??
        result['examName'] as String? ??
        'Test';

    final obtained = _number(result['obtainedMarks']);
    final total = _number(result['totalMarks']);

    final percentage =
        total > 0 ? (obtained / total) * 100 : 0.0;

    final progress =
        (percentage / 100).clamp(0.0, 1.0).toDouble();

    final formattedDate = _formatDate(result['date']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4F3E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: _darkGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatMarks(obtained)} / ${_formatMarks(total)} marks'
                      '  •  ${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: const Color(0xFF4CAF50),
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubjectResults extends StatelessWidget {
  const _EmptySubjectResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            color: Color(0xFF105C3B),
            size: 46,
          ),
          SizedBox(height: 14),
          Text(
            'No Individual Test Results',
            style: TextStyle(
              color: Color(0xFF202B25),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no unexpired individual test results available for this subject. The saved average above can still include expired tests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68766E),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}