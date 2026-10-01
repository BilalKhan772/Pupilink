import 'package:flutter/material.dart';

class ChildLinkPendingScreen
    extends StatelessWidget {
  final String studentName;

  const ChildLinkPendingScreen({
    super.key,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Link Request',
        ),
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top,
                size: 80,
              ),

              const SizedBox(height: 25),

              const Text(
                'Request Pending',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '$studentName ki linking request '
                'submit ho gayi hai.',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'School verification ke baad '
                'child aapke account mein show hoga.',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to My Children',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}