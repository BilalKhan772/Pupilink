import 'package:flutter/material.dart';

class UpcomingTestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final VoidCallback? onTap;

  const UpcomingTestCard({
    super.key,
    required this.test,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subject =
        test['subject'] as String? ?? 'Subject';

    final testName =
        test['testName'] as String? ?? 'Test';

    final date =
        test['date'] as String? ?? '';

    final description =
        test['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(
                      Icons.quiz,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          testName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date.isEmpty
                        ? 'Date not available'
                        : date,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}