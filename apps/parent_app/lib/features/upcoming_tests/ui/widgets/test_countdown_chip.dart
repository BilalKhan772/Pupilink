import 'package:flutter/material.dart';

class TestCountdownChip extends StatelessWidget {
  final String date;

  const TestCountdownChip({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final countdownText = _getCountdownText();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        countdownText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getCountdownText() {
    final testDate = DateTime.tryParse(date);

    if (testDate == null) {
      return 'Date unavailable';
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final normalizedTestDate = DateTime(
      testDate.year,
      testDate.month,
      testDate.day,
    );

    final difference =
        normalizedTestDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Tomorrow';
    }

    if (difference > 1) {
      return '$difference days left';
    }

    return 'Date passed';
  }
}