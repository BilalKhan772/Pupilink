
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentResultsRepository {
  final FirebaseFirestore firestore;

  ParentResultsRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  /// Temporary test results.
  /// Expired results are excluded from the Parent App.
  Future<List<Map<String, dynamic>>> getResults({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception('Student ID available nahi hai.');
    }

    final snapshot = await firestore
        .collection('results')
        .where('studentId', isEqualTo: studentId)
        .where(
          'expiresAt',
          isGreaterThan: Timestamp.now(),
        )
        .orderBy('expiresAt')
        .get();

    return snapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).toList();
  }

  /// Permanent subject averages.
  /// These documents must not be deleted by result expiry cleanup.
  Future<List<Map<String, dynamic>>> getSubjectAverages({
    required String studentId,
    required String schoolId,
  }) async {
    if (studentId.isEmpty || schoolId.isEmpty) {
      throw Exception(
        'Student ID ya School ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('subjectAverages')
        .where('studentId', isEqualTo: studentId)
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final averages = snapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).toList();

    averages.sort((a, b) {
      final subjectA = (a['subject'] ?? 'Subject')
          .toString()
          .toLowerCase();
      final subjectB = (b['subject'] ?? 'Subject')
          .toString()
          .toLowerCase();

      return subjectA.compareTo(subjectB);
    });

    return averages;
  }

  /// Permanent overall student average.
  Future<Map<String, dynamic>?> getStudentAverage({
    required String studentId,
    required String schoolId,
  }) async {
    if (studentId.isEmpty || schoolId.isEmpty) {
      throw Exception(
        'Student ID ya School ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('studentAverages')
        .where('studentId', isEqualTo: studentId)
        .where('schoolId', isEqualTo: schoolId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return {
      'id': document.id,
      ...document.data(),
    };
  }
}
