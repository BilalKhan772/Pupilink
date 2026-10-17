
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_firebase/school_firebase.dart';
import 'package:school_models/school_models.dart';

final attendanceSummaryRepositoryProvider =
    Provider<AttendanceSummaryRepository>((ref) {
  return AttendanceSummaryRepository(firestore: FirestoreClient());
});

class AttendanceSummaryRepository {
  AttendanceSummaryRepository({required FirestoreClient firestore})
      : _firestore = firestore;

  final FirestoreClient _firestore;

  Future<List<AttendanceSummary>> getSummaries({
    required String schoolId,
    String? studentId,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('School ID required hai.');
    }

    var query = _firestore
        .collection(FirestoreCollections.attendanceSummaries)
        .where('schoolId', isEqualTo: schoolId);

    if (studentId != null && studentId.trim().isNotEmpty) {
      query = query.where('studentId', isEqualTo: studentId);
    }

    final snapshot = await query.get();

    final summaries = snapshot.docs
        .map((doc) => AttendanceSummary.fromMap(doc.id, doc.data()))
        .toList();

    summaries.sort((a, b) => b.attendancePercentage
        .compareTo(a.attendancePercentage));

    return summaries;
  }
}
