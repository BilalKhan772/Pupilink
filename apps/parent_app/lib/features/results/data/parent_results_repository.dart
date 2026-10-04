import 'package:cloud_firestore/cloud_firestore.dart';

class ParentResultsRepository {
  final FirebaseFirestore firestore;

  ParentResultsRepository({
    FirebaseFirestore? firestore,
  }) : firestore =
            firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getResults({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception(
        'Student ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('results')
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

    return records;
  }
}