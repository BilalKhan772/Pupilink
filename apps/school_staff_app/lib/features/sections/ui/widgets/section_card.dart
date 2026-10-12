
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.section,
    required this.className,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SchoolSection section;
  final String className;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final activeColor = section.isActive
        ? const Color(0xFF16A34A)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Section actions',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'toggle') onToggleActive();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit section'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      section.isActive ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            section.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            className.isEmpty ? 'Class not found' : className,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (section.capacity != null)
            Text(
              'Capacity: ${section.capacity} students',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: activeColor),
              const SizedBox(width: 7),
              Text(
                section.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right),
                label: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
