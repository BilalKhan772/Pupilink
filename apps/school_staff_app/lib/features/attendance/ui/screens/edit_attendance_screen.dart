
import 'package:flutter/material.dart';

import 'attendance_screen.dart';

class EditAttendanceScreen extends StatelessWidget {
  const EditAttendanceScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.sectionId,
    required this.staffId,
  });

  final String schoolId;
  final String classId;
  final String sectionId;
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return AttendanceScreen(
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
      staffId: staffId,
    );
  }
}
