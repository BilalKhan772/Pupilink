
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class ClassOverviewScreen extends StatelessWidget {
  const ClassOverviewScreen({
    super.key,
    required this.schoolClass,
    required this.academicYearName,
  });

  final SchoolClass schoolClass;
  final String academicYearName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Overview')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.class_rounded,
                  size: 44,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                Text(
                  schoolClass.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(schoolClass.isActive ? 'Active' : 'Inactive'),
                  avatar: Icon(
                    schoolClass.isActive
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    size: 18,
                  ),
                ),
                const Divider(height: 32),
                _DetailRow(label: 'School ID', value: schoolClass.schoolId),
                _DetailRow(
                  label: 'Academic year',
                  value: academicYearName.isEmpty
                      ? 'Not assigned'
                      : academicYearName,
                ),
                _DetailRow(
                  label: 'Display order',
                  value: schoolClass.sortOrder?.toString() ?? 'Not set',
                ),
                _DetailRow(label: 'Class document ID', value: schoolClass.id),
                _DetailRow(
                  label: 'Created',
                  value: schoolClass.createdAt?.toLocal().toString() ??
                      'Not available',
                ),
                _DetailRow(
                  label: 'Last updated',
                  value: schoolClass.updatedAt?.toLocal().toString() ??
                      'Not available',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Students aur sections ki management abhi separate modules mein connect ki jayegi.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
