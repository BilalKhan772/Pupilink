import 'package:cloud_firestore/cloud_firestore.dart';

class ParentAttendanceRepository {
  final FirebaseFirestore firestore;

  ParentAttendanceRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAttendance({
    required String studentId,
  }) async {
    final normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      throw Exception('Student ID available nahi hai.');
    }

    // Class Teacher attendanceRecords mein attendance save karta hai.
    // Is liye Parent App bhi isi collection se records read karega.
    final snapshot = await firestore
        .collection('attendanceRecords')
        .where(
          'studentId',
          isEqualTo: normalizedStudentId,
        )
        .get();

    final records = snapshot.docs.map((document) {
      final data = document.data();

      return <String, dynamic>{
        'id': document.id,
        ...data,
      };
    }).toList();

    // Newest attendance pehle show hogi.
    records.sort((a, b) {
      final dateA = _parseDate(a['date']);
      final dateB = _parseDate(b['date']);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    return records;
  }

  /// Firestore Timestamp, DateTime aur String dates handle karta hai.
  DateTime? _parseDate(dynamic value) {
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