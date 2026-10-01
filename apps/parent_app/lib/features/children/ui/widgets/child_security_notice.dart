import 'package:flutter/material.dart';

class ChildSecurityNotice extends StatelessWidget {
  const ChildSecurityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.security,
              color: Colors.blue,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                'Child link request school verification ke '
                'baad approve hogi. Sirf apne child ki '
                'correct information enter karein.',
                style: TextStyle(
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}