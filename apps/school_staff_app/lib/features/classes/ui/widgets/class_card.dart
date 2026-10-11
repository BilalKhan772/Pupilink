
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.schoolClass,
    required this.academicYearName,
    required this.onEdit,
    required this.onToggleActive,
    required this.onOpen,
  });

  final SchoolClass schoolClass;
  final String academicYearName;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final active = schoolClass.isActive;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Class actions',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'toggle') onToggleActive();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit class'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(active ? 'Deactivate' : 'Activate'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                schoolClass.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                academicYearName.isEmpty
                    ? 'Academic year not assigned'
                    : academicYearName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    active ? Icons.check_circle : Icons.pause_circle,
                    size: 17,
                    color: active
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View details',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
