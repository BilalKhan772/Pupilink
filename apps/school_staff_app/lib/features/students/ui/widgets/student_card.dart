
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
  });

  final Student student;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: student.photoUrl == null
                      ? null
                      : NetworkImage(student.photoUrl!),
                  child: student.photoUrl == null
                      ? const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggleActive();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit student'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        student.isActive ? 'Deactivate' : 'Activate',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Admission: ${student.admissionNumber}'),
            const SizedBox(height: 6),
            Text('Class ${student.className} • Section ${student.section}'),
            const SizedBox(height: 6),
            Text(
              student.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: student.isActive
                    ? const Color(0xFF15803D)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
