
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class SectionManagementTile extends StatelessWidget {
  const SectionManagementTile({
    super.key,
    required this.section,
    required this.className,
    this.onTap,
  });

  final SchoolSection section;
  final String className;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEFF6FF),
        child: const Icon(
          Icons.meeting_room_outlined,
          color: Color(0xFF2563EB),
        ),
      ),
      title: Text('${className.isEmpty ? 'Class' : className} - ${section.name}'),
      subtitle: Text(section.isActive ? 'Active' : 'Inactive'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
