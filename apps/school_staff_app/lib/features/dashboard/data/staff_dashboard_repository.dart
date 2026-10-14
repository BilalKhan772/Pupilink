
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

final staffDashboardRepositoryProvider =
    Provider<StaffDashboardRepository>((ref) {
  return StaffDashboardRepository(
    firestore: FirebaseFirestore.instance,
  );
});

class StaffDashboardRepository {
  StaffDashboardRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection(
        FirestoreCollections.teacherAssignments,
      );

  /// Loads active assignments for a specific teacher.
  ///
  /// Both schoolId and teacherId are required so that assignments
  /// from another school or another teacher are not returned.
  Future<List<TeacherAssignment>> getTeacherAssignments({
    required String schoolId,
    required String teacherId,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('School ID missing hai.');
    }

    if (teacherId.trim().isEmpty) {
      throw ArgumentError('Teacher ID missing hai.');
    }

    final snapshot = await _assignments
        .where('schoolId', isEqualTo: schoolId)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TeacherAssignment.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  /// Returns active assignments for one particular section.
  Future<List<TeacherAssignment>> getSectionAssignments({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty ||
        sectionId.trim().isEmpty) {
      throw ArgumentError(
        'School ID aur Section ID required hain.',
      );
    }

    final snapshot = await _assignments
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TeacherAssignment.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}
