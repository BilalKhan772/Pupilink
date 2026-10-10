import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingTestsRepository {
  final FirebaseFirestore firestore;

  UpcomingTestsRepository({
    FirebaseFirestore? firestore,
  }) : firestore =
            firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getUpcomingTests({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception(
        'Student ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('upcoming_tests')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .get();

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final records =
        snapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).where((record) {
      final dateString =
          record['date'] as String? ?? '';

      final testDate =
          DateTime.tryParse(dateString);

      if (testDate == null) {
        return false;
      }

      final normalizedTestDate = DateTime(
        testDate.year,
        testDate.month,
        testDate.day,
      );

      return !normalizedTestDate.isBefore(
        today,
      );
    }).toList();

    records.sort((a, b) {
      final dateA =
          a['date'] as String? ?? '';

      final dateB =
          b['date'] as String? ?? '';

      return dateA.compareTo(dateB);
    });

    return records;
  }
}