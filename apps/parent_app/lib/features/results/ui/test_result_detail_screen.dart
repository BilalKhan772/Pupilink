import 'package:flutter/material.dart';

class TestResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const TestResultDetailScreen({
    super.key,
    required this.result,
  });

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  double _number(dynamic value) => value is num ? value.toDouble() : 0.0;

  String _formatMarks(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final subject = result['subject'] as String? ?? 'Subject';
    final obtainedMarks = _number(result['obtainedMarks']);
    final totalMarks = _number(result['totalMarks']);
    final percentage = totalMarks > 0
        ? obtainedMarks / totalMarks * 100
        : 0.0;
    final grade = result['grade'] as String? ?? _calculateGrade(percentage);
    final examName = result['examName'] as String? ??
        result['testName'] as String? ??
        'Test Result';
    final date = _formatDate(result['date']);
    final progress = (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Result Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
          final maxWidth = constraints.maxWidth >= 1000
              ? 860.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxWidth,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 36),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF163B28).withValues(alpha: 0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5F3E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: _darkGreen,
                            size: 31,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          subject,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          examName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            date,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          '${_formatMarks(obtainedMarks)} / ${_formatMarks(totalMarks)}',
                          style: const TextStyle(
                            color: _darkGreen,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            color: _green,
                            backgroundColor: const Color(0xFFDCEBE1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F3E9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Grade: $grade',
                            style: const TextStyle(
                              color: _darkGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Result Summary',
                    style: TextStyle(
                      color: _text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Obtained Marks',
                    value: _formatMarks(obtainedMarks),
                  ),
                  _InfoCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Total Marks',
                    value: _formatMarks(totalMarks),
                  ),
                  _InfoCard(
                    icon: Icons.track_changes_outlined,
                    title: 'Percentage',
                    value: '${percentage.toStringAsFixed(1)}%',
                  ),
                  _InfoCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Grade',
                    value: grade,
                  ),
                  if (date.isNotEmpty)
                    _InfoCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Test Date',
                      value: date,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is int) {
      date = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (date == null) return value.toString();
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F3E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF105C3B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF68766E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF202B25),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMarks(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
