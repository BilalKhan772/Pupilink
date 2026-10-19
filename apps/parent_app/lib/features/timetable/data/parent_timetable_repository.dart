
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentTimetableRepository {
  final FirebaseFirestore firestore;

  ParentTimetableRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getTimetable({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw Exception(
        'Student ka school ya section ID available nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('timetable')
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .get();

    final records = snapshot.docs.map((document) {
      return <String, dynamic>{
        'id': document.id,
        ...document.data(),
      };
    }).toList();

    records.sort((a, b) {
      final startA = a['startTime']?.toString() ?? '';
      final startB = b['startTime']?.toString() ?? '';
      return startA.compareTo(startB);
    });

    return records;
  }
}
