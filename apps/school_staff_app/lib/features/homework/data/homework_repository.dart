
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository();
});

class HomeworkRepository {
  HomeworkRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> getMonitorAssignment() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Pehle monitor account se login karein.');
    }

    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (!snapshot.exists) {
      throw Exception('Monitor profile nahi mila.');
    }

    final data = snapshot.data()!;
    final role = data['role'] as String? ?? '';

    if (role != 'monitor') {
      throw Exception('Yeh feature sirf monitor account ke liye hai.');
    }

    final schoolId = data['schoolId'] as String? ?? '';
    final classId = data['classId'] as String? ?? '';
    final sectionId = data['sectionId'] as String? ?? '';
    final sectionName = data['sectionName'] as String? ?? '';
    final monitorName = data['name'] as String? ?? '';

    if (schoolId.isEmpty || sectionId.isEmpty) {
      throw Exception(
        'Monitor ki school ya section assignment profile mein missing hai.',
      );
    }

    return {
      'uid': user.uid,
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'monitorName': monitorName,
    };
  }

  Future<int> publishHomework({
    required String title,
    required String subject,
    required String description,
    required DateTime dueDate,
  }) async {
    final assignment = await getMonitorAssignment();

    final schoolId = assignment['schoolId'] as String;
    final classId = assignment['classId'] as String;
    final sectionId = assignment['sectionId'] as String;
    final monitorUid = assignment['uid'] as String;

    final studentsSnapshot = await _firestore
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .get();

    if (studentsSnapshot.docs.isEmpty) {
      throw Exception(
        'Is section mein koi student nahi mila. Students ke documents mein schoolId aur sectionId verify karein.',
      );
    }

    final now = DateTime.now();
    final dueDateString = dueDate.toIso8601String();
    final students = studentsSnapshot.docs;

    // Firestore batch ki limit 500 writes hai.
    // Har student ke liye ek record create hota hai.
    for (var start = 0; start < students.length; start += 450) {
      final end = (start + 450 < students.length)
          ? start + 450
          : students.length;

      final batch = _firestore.batch();

      for (final student in students.sublist(start, end)) {
        final homeworkRef = _firestore.collection('homework').doc();

        batch.set(homeworkRef, {
          'schoolId': schoolId,
          'classId': classId,
          'sectionId': sectionId,
          'studentId': student.id,
          'subject': subject.trim(),
          'title': title.trim(),
          'description': description.trim(),
          'attachmentUrl': null,
          'assignedBy': monitorUid,
          'assignedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'dueDate': dueDateString,
          'status': 'pending',
        });
      }

      await batch.commit();
    }

    return students.length;
  }
}
