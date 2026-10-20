
import 'package:flutter/material.dart';

class HomeworkDetailScreen extends StatelessWidget {
  final Map<String, dynamic> homework;

  const HomeworkDetailScreen({
    super.key,
    required this.homework,
  });

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value.isEmpty ? 'Not available' : value;

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = homework['title'] as String? ?? 'Homework';
    final description = homework['description'] as String? ?? '';
    final dueDate = homework['dueDate'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 35,
            child: Icon(Icons.menu_book, size: 35),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          _detailCard(
            title: 'Description',
            value: description.isEmpty
                ? 'No description available.'
                : description,
          ),
          _detailCard(
            title: 'Due Date',
            value: _formatDate(dueDate),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(value),
          ],
        ),
      ),
    );
  }
}
