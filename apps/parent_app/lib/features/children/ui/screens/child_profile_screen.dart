import 'package:flutter/material.dart';

class ChildProfileScreen
    extends StatelessWidget {
  final Map<String, dynamic> child;

  const ChildProfileScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        child['name'] as String? ??
            'Unknown Student';

    final admissionNumber =
        child['admissionNumber']
                as String? ??
            '';

    final schoolName =
        child['schoolName']
                as String? ??
            '';

    final className =
        child['className']
                as String? ??
            '';

    final section =
        child['section']
                as String? ??
            '';

    final city =
        child['city'] as String? ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Child Profile',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 25),

          _infoCard(
            'Admission Number',
            admissionNumber,
          ),

          _infoCard(
            'School',
            schoolName,
          ),

          _infoCard(
            'City',
            city,
          ),

          _infoCard(
            'Class',
            className,
          ),

          _infoCard(
            'Section',
            section,
          ),

          const SizedBox(height: 20),

          const Text(
            'Academic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _featureCard(
            Icons.menu_book,
            'Homework',
          ),

          _featureCard(
            Icons.fact_check,
            'Attendance',
          ),

          _featureCard(
            Icons.assessment,
            'Results',
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value.isEmpty
              ? 'Not available'
              : value,
        ),
      ),
    );
  }

  Widget _featureCard(
    IconData icon,
    String title,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {},
      ),
    );
  }
}