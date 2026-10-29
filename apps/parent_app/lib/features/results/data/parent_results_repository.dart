import 'package:cloud_firestore/cloud_firestore.dart';

class ParentResultsRepository {
  final FirebaseFirestore firestore;

  ParentResultsRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<_StudentScope?> _readStudentScope({
    required String studentId,
    required String? expectedSchoolId,
  }) async {
    final snapshot = await firestore.collection('students').doc(studentId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final actualSchoolId = (data['schoolId'] as String? ?? '').trim();
    if (expectedSchoolId != null &&
        expectedSchoolId.trim().isNotEmpty &&
        actualSchoolId.isNotEmpty &&
        actualSchoolId != expectedSchoolId.trim()) {
      throw StateError('The selected student does not belong to this school.');
    }

    return _StudentScope(
      schoolId: actualSchoolId,
      classId: (data['classId'] as String? ?? '').trim(),
      sectionId: (data['sectionId'] as String? ?? '').trim(),
    );
  }

  bool _matchesScope({
    required Map<String, dynamic> data,
    required _StudentScope? scope,
    required String expectedStudentId,
    required String? expectedSchoolId,
  }) {
    if (data['studentId'] != expectedStudentId) return false;

    final expectedSchool = expectedSchoolId?.trim() ?? '';
    final recordSchool = (data['schoolId'] as String? ?? '').trim();
    final scopeSchool = scope?.schoolId ?? '';

    if (expectedSchool.isNotEmpty &&
        recordSchool.isNotEmpty &&
        recordSchool != expectedSchool) {
      return false;
    }

    if (scopeSchool.isNotEmpty &&
        recordSchool.isNotEmpty &&
        recordSchool != scopeSchool) {
      return false;
    }

    // Ignore an explicitly conflicting class/section. Legacy records with
    // missing scope fields are retained so previously saved averages are not
    // silently discarded before their records can be repaired/recomputed.
    final classId = scope?.classId ?? '';
    final recordClassId = (data['classId'] as String? ?? '').trim();
    if (classId.isNotEmpty &&
        recordClassId.isNotEmpty &&
        recordClassId != classId) {
      return false;
    }

    final sectionId = scope?.sectionId ?? '';
    final recordSectionId = (data['sectionId'] as String? ?? '').trim();
    if (sectionId.isNotEmpty &&
        recordSectionId.isNotEmpty &&
        recordSectionId != sectionId) {
      return false;
    }

    return true;
  }

  /// Temporary, individual results. Expired records are excluded.
  /// This method never deletes marks or permanent averages.
  Future<List<Map<String, dynamic>>> getResults({
    required String studentId,
    String? schoolId,
  }) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      throw ArgumentError('Student ID is missing.');
    }

    final normalizedSchoolId = schoolId?.trim();
    final scope = await _readStudentScope(
      studentId: normalizedStudentId,
      expectedSchoolId: normalizedSchoolId,
    );

    final snapshot = await firestore
        .collection('results')
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .get();

    return snapshot.docs
        .map((document) => <String, dynamic>{
              ...document.data(),
              'id': document.id,
            })
        .where((data) => _matchesScope(
              data: data,
              scope: scope,
              expectedStudentId: normalizedStudentId,
              expectedSchoolId: normalizedSchoolId,
            ))
        .toList();
  }

  /// Permanent subject averages. These documents are not deleted by expiry.
  Future<List<Map<String, dynamic>>> getSubjectAverages({
    required String studentId,
    required String schoolId,
  }) async {
    final normalizedStudentId = studentId.trim();
    final normalizedSchoolId = schoolId.trim();

    if (normalizedStudentId.isEmpty || normalizedSchoolId.isEmpty) {
      throw ArgumentError('Student ID or School ID is missing.');
    }

    final scope = await _readStudentScope(
      studentId: normalizedStudentId,
      expectedSchoolId: normalizedSchoolId,
    );

    final snapshot = await firestore
        .collection('subjectAverages')
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .get();

    final averages = snapshot.docs
        .map((document) => <String, dynamic>{
              ...document.data(),
              'id': document.id,
            })
        .where((data) => _matchesScope(
              data: data,
              scope: scope,
              expectedStudentId: normalizedStudentId,
              expectedSchoolId: normalizedSchoolId,
            ))
        .toList();

    averages.sort((a, b) {
      final subjectA = (a['subject'] ?? a['subjectName'] ?? 'Subject')
          .toString()
          .toLowerCase();
      final subjectB = (b['subject'] ?? b['subjectName'] ?? 'Subject')
          .toString()
          .toLowerCase();
      return subjectA.compareTo(subjectB);
    });

    return averages;
  }

  /// Permanent overall average. A mismatched saved scope is not returned;
  /// the UI can calculate a fallback from valid subject averages instead.
  Future<Map<String, dynamic>?> getStudentAverage({
    required String studentId,
    required String schoolId,
  }) async {
    final normalizedStudentId = studentId.trim();
    final normalizedSchoolId = schoolId.trim();

    if (normalizedStudentId.isEmpty || normalizedSchoolId.isEmpty) {
      throw ArgumentError('Student ID or School ID is missing.');
    }

    final scope = await _readStudentScope(
      studentId: normalizedStudentId,
      expectedSchoolId: normalizedSchoolId,
    );

    final snapshot = await firestore
        .collection('studentAverages')
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .limit(1)
        .get();

    for (final document in snapshot.docs) {
      final data = <String, dynamic>{
        ...document.data(),
        'id': document.id,
      };

      if (_matchesScope(
        data: data,
        scope: scope,
        expectedStudentId: normalizedStudentId,
        expectedSchoolId: normalizedSchoolId,
      )) {
        return data;
      }
    }

    return null;
  }
}

class _StudentScope {
  const _StudentScope({
    required this.schoolId,
    required this.classId,
    required this.sectionId,
  });

  final String schoolId;
  final String classId;
  final String sectionId;
}
