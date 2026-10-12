
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class StudentOverviewScreen extends StatelessWidget {
  const StudentOverviewScreen({
    super.key,
    required this.student,
  });

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundImage: student.photoUrl == null
                  ? null
                  : NetworkImage(student.photoUrl!),
              child: student.photoUrl == null
                  ? const Icon(Icons.person, size: 42)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              student.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(student.isActive ? 'Active' : 'Inactive'),
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(label: 'Admission number', value: student.admissionNumber),
          _DetailRow(label: 'School', value: student.schoolName),
          _DetailRow(label: 'City', value: student.city),
          _DetailRow(label: 'Class', value: student.className),
          _DetailRow(label: 'Section', value: student.section),
          _DetailRow(label: 'Student document ID', value: student.id),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
