import 'package:cloud_firestore/cloud_firestore.dart';

class ParentHomeworkRepository {
  final FirebaseFirestore firestore;

  ParentHomeworkRepository({
    FirebaseFirestore? firestore,
  }) : firestore =
            firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getHomework({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception(
        'Student ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('homework')
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
          a['dueDate'] as String? ?? '';

      final dateB =
          b['dueDate'] as String? ?? '';

      return dateA.compareTo(dateB);
    });

    return records;
  }
}