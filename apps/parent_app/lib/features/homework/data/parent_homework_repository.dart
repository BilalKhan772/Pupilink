
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentHomeworkRepository {
  final FirebaseFirestore firestore;

  ParentHomeworkRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getHomework({
    required String studentId,
  }) async {
    if (studentId.isEmpty) {
      throw Exception('Student ID available nahi hai.');
    }

    final snapshot = await firestore
        .collection('homework')
        .where('studentId', isEqualTo: studentId)
        .get();

    final now = DateTime.now();

    final records = snapshot.docs.map((document) {
      return <String, dynamic>{
        'id': document.id,
        ...document.data(),
      };
    }).where((record) {
      final assignedAt = _dateValue(record['assignedAt']);

      // Expiry date maloom na ho to record ko list mein na dikhayein.
      if (assignedAt == null) return false;

      // Upload date ke 2 calendar days baad raat 12 baje expiry.
      final localAssignedAt = assignedAt.toLocal();
      final expiryDate = DateTime(
        localAssignedAt.year,
        localAssignedAt.month,
        localAssignedAt.day + 2,
      );

      return now.isBefore(expiryDate);
    }).toList();

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
}
