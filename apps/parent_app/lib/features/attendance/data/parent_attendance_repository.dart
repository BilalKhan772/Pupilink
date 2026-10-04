import 'package:cloud_firestore/cloud_firestore.dart';

class ParentAttendanceRepository {
  final FirebaseFirestore firestore;

  ParentAttendanceRepository({
    FirebaseFirestore? firestore,
  }) : firestore =
            firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAttendance({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception(
        'Student ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('attendance')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .get();

    final records =
        snapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).toList();

    records.sort((a, b) {
      final dateA =
          a['date'] as String? ?? '';

      final dateB =
          b['date'] as String? ?? '';

      return dateB.compareTo(dateA);
    });

    return records;
  }
}