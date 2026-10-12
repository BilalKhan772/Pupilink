
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

  static const Color _green = Color(0xFF15803D);
  static const Color _text = Color(0xFF172B24);
  static const Color _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final active = schoolClass.isActive;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 27,
                      color: _green,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'Class actions',
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: _muted,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'toggle') onToggleActive();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 19),
                              SizedBox(width: 10),
                              Text('Edit class'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.pause_circle_outline
                                    : Icons.check_circle_outline,
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Text(active ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                schoolClass.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 17,
                    color: _muted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      academicYearName.isEmpty
                          ? 'Academic year not assigned'
                          : academicYearName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEFF2F6)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_outline_rounded,
                          size: 15,
                          color: active ? _green : _muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: active ? _green : _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Flexible(
                    child: Text(
                      'View details',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: _green,
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
