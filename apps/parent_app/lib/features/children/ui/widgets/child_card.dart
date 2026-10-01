import 'package:flutter/material.dart';

class ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;

  const ChildCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        child['name'] as String? ??
            'Unknown Student';

    final school =
        child['schoolName'] as String? ??
            '';

    final className =
        child['className'] as String? ??
            '';

    final section =
        child['section'] as String? ??
            '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                child: Icon(
                  Icons.person,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(school),

                    const SizedBox(height: 3),

                    Text(
                      'Class: $className'
                      '${section.isEmpty ? '' : ' • $section'}',
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}