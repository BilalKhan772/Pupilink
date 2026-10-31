
import 'package:flutter/material.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({
    super.key,
    required this.child,
    required this.onTap,
    this.onRemove,
    this.isRemoving = false,
  });

  final Map<String, dynamic> child;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isRemoving;

  @override
  Widget build(BuildContext context) {
    final name = child['name'] as String? ?? 'Unknown Student';
    final school = child['schoolName'] as String? ?? '';
    final className = child['className'] as String? ?? '';
    final section = child['section'] as String? ?? '';
    final admission = child['admissionNumber'] as String? ?? '';

    final classSection = [
      if (className.trim().isNotEmpty) 'Class: $className',
      if (section.trim().isNotEmpty) 'Section: $section',
    ].join('  •  ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EAE3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D28).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: isRemoving ? null : onTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 17, 8, 17),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2E8),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Text(
                            name.trim().isEmpty
                                ? '?'
                                : name.trim()[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF105C3B),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF203329),
                              ),
                            ),
                            if (school.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                school,
                                style: const TextStyle(
                                  color: Color(0xFF718078),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (classSection.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                classSection,
                                style: const TextStyle(
                                  color: Color(0xFF56685D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (admission.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Admission No: $admission',
                                style: const TextStyle(
                                  color: Color(0xFF89958D),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFF718078),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isRemoving
                ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    tooltip: 'Child options',
                    enabled: onRemove != null,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF718078),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    onSelected: (value) {
                      if (value == 'remove') {
                        onRemove?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_off_rounded,
                              color: Color(0xFFB42318),
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Remove Child',
                              style: TextStyle(
                                color: Color(0xFFB42318),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
