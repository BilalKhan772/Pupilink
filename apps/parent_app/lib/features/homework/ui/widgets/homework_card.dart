import 'package:flutter/material.dart';

class HomeworkCard extends StatelessWidget {
  final Map<String, dynamic> homework;
  final VoidCallback onTap;

  const HomeworkCard({
    super.key,
    required this.homework,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subject =
        homework['subject'] as String? ??
            'Subject';

    final title =
        homework['title'] as String? ??
            'Homework';

    final description =
        homework['description'] as String? ??
            '';

    final dueDate =
        homework['dueDate'] as String? ??
            '';

    final status =
        homework['status'] as String? ??
            'pending';

    final isCompleted =
        status.toLowerCase() == 'completed';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : Icons.menu_book,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  _statusBadge(
                    status,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color:
                        Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dueDate.isEmpty
                        ? 'Due date not available'
                        : 'Due: $dueDate',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized =
        status.toLowerCase();

    String text;

    if (normalized == 'completed') {
      text = 'Completed';
    } else if (normalized == 'pending') {
      text = 'Pending';
    } else {
      text = status;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color: normalized == 'completed'
            ? Colors.green.shade100
            : Colors.orange.shade100,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
          color:
              normalized == 'completed'
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
        ),
      ),
    );
  }
}