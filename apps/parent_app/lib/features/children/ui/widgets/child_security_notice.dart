
import 'package:flutter/material.dart';

class ChildSecurityNotice extends StatelessWidget {
  const ChildSecurityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD5EBDD),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF138A4B),
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Child Verification',
                  style: TextStyle(
                    color: Color(0xFF105C3B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your request will be sent to the school for '
                  'verification. Please make sure the city, school '
                  'and admission number are correct.',
                  style: TextStyle(
                    color: Color(0xFF536D5C),
                    fontSize: 12,
                    height: 1.5,
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
