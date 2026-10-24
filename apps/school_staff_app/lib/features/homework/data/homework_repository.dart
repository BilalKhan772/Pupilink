
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeworkRepositoryProvider =
    Provider<HomeworkRepository>((ref) => HomeworkRepository());

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

    var className = '';

    if (classId.isNotEmpty) {
      final classSnapshot =
          await _firestore.collection('classes').doc(classId).get();

      if (classSnapshot.exists) {
        className = classSnapshot.data()?['name'] as String? ?? '';
      }
    }

    return {
      'uid': user.uid,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'monitorName': monitorName,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentHomework({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.isEmpty || sectionId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final snapshot = await _firestore
        .collection('homework')
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .get();

    final now = DateTime.now();

    final records = snapshot.docs
        .map(
          (document) => <String, dynamic>{
            'id': document.id,
            ...document.data(),
          },
        )
        .where((record) {
          final assignedAt = _dateValue(record['assignedAt']);

          // Missing upload date wale records ko list mein na dikhayein.
          if (assignedAt == null) return false;

          final localAssignedAt = assignedAt.toLocal();

          // Upload date ke 2 calendar days baad raat 12 baje expiry.
          final expiryDate = DateTime(
            localAssignedAt.year,
            localAssignedAt.month,
            localAssignedAt.day + 2,
          );

          return now.isBefore(expiryDate);
        })
        .toList();

    // Latest uploaded homework sab se upar.
    records.sort((a, b) {
      final dateA = _dateValue(a['assignedAt']);
      final dateB = _dateValue(b['assignedAt']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return records;
  }

  DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Future<int> publishHomework({
    required String title,
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
        'Is section mein koi student nahi mila. '
        'Students ke documents mein schoolId aur sectionId verify karein.',
      );
    }

    final dueDateString =
        '${dueDate.year.toString().padLeft(4, '0')}-'
        '${dueDate.month.toString().padLeft(2, '0')}-'
        '${dueDate.day.toString().padLeft(2, '0')}';

    final students = studentsSnapshot.docs;

    for (var start = 0; start < students.length; start += 450) {
      final end =
          start + 450 < students.length ? start + 450 : students.length;

      final batch = _firestore.batch();

      for (final student in students.sublist(start, end)) {
        final homeworkRef = _firestore.collection('homework').doc();

        batch.set(homeworkRef, {
          'schoolId': schoolId,
          'classId': classId,
          'sectionId': sectionId,
          'studentId': student.id,
          'subject': 'Homework',
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
