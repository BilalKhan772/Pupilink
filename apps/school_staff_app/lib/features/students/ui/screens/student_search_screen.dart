
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/students_controller.dart';
import 'student_overview_screen.dart';

class StudentSearchScreen extends ConsumerStatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  ConsumerState<StudentSearchScreen> createState() =>
      _StudentSearchScreenState();
}

class _StudentSearchScreenState extends ConsumerState<StudentSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentsControllerProvider);
    final query = _query.trim().toLowerCase();

    final matches = query.isEmpty
        ? const []
        : state.students
            .where(
              (student) => student.admissionNumber.toLowerCase() == query,
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Student')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: 'Admission number',
              hintText: 'e.g. STU-1001',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (query.isNotEmpty && matches.isEmpty)
            const Text('Is admission number ka student nahi mila.')
          else
            for (final student in matches)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(student.name),
                  subtitle: Text(
                    '${student.admissionNumber} • Class ${student.className}-${student.section}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentOverviewScreen(student: student),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
