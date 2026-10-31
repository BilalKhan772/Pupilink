
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableRepository {
  TimetableRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _timetable =>
      _firestore.collection('timetable');

  // ---------------------------------------------------------------------------
  // Get timetable
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTimetable({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError(
        'School ID and Section ID are required.',
      );
    }

    final snapshot = await _timetable
        .where('schoolId', isEqualTo: schoolId.trim())
        .where('sectionId', isEqualTo: sectionId.trim())
        .get();

    final records = snapshot.docs.map((doc) {
      return <String, dynamic>{
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    records.sort((a, b) {
      final dayCompare = _dayOrder(
        a['day'] as String?,
      ).compareTo(
        _dayOrder(b['day'] as String?),
      );

      if (dayCompare != 0) return dayCompare;

      return (a['startTime'] as String? ?? '')
          .compareTo(b['startTime'] as String? ?? '');
    });

    return records;
  }

  // ---------------------------------------------------------------------------
  // Add / Update timetable entry
  // ---------------------------------------------------------------------------

  Future<void> saveTimetableEntry({
    String? entryId,
    required String schoolId,
    required String classId,
    required String className,
    required String sectionId,
    required String sectionName,
    required String day,
    required String subject,
    required String teacherName,
    required String startTime,
    required String endTime,
    String room = '',
  }) async {
    final values = [
      schoolId,
      classId,
      sectionId,
      day,
      subject,
      startTime,
      endTime,
    ];

    if (values.any((value) => value.trim().isEmpty)) {
      throw ArgumentError(
        'Please complete all required fields.',
      );
    }

    if (_timeToMinutes(endTime) <= _timeToMinutes(startTime)) {
      throw ArgumentError(
        'End time must be later than start time.',
      );
    }

    final data = <String, dynamic>{
      'schoolId': schoolId.trim(),
      'classId': classId.trim(),
      'className': className.trim(),
      'sectionId': sectionId.trim(),
      'sectionName': sectionName.trim(),
      'day': day.trim(),
      'subject': subject.trim(),
      'subjectName': subject.trim(),
      'teacherName': teacherName.trim(),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'room': room.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (entryId == null || entryId.trim().isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();

      await _timetable.add(data);
    } else {
      final documentRef = _timetable.doc(entryId.trim());
      final existing = await documentRef.get();

      if (!existing.exists ||
          existing.data()?['schoolId'] != schoolId.trim() ||
          existing.data()?['sectionId'] != sectionId.trim()) {
        throw Exception(
          'Timetable entry was not found or access could not be verified.',
        );
      }

      await documentRef.update(data);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete timetable entry
  // ---------------------------------------------------------------------------

  Future<void> deleteTimetableEntry({
    required String entryId,
    required String schoolId,
    required String sectionId,
  }) async {
    if (entryId.trim().isEmpty) {
      throw ArgumentError(
        'Timetable entry ID is required.',
      );
    }

    final ref = _timetable.doc(entryId.trim());
    final snapshot = await ref.get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != schoolId.trim() ||
        snapshot.data()?['sectionId'] != sectionId.trim()) {
      throw Exception(
        'Timetable entry was not found or access could not be verified.',
      );
    }

    await ref.delete();
  }

  // ---------------------------------------------------------------------------
  // Day sorting
  // ---------------------------------------------------------------------------

  static int _dayOrder(String? day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days.indexOf(day ?? '');
  }

  // ---------------------------------------------------------------------------
  // Time validation
  // ---------------------------------------------------------------------------

  static int _timeToMinutes(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) {
      throw ArgumentError(
        'Time must use the HH:mm format.',
      );
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError(
        'Please enter a valid time.',
      );
    }

    return hour * 60 + minute;
  }
}
