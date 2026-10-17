
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_firebase/school_firebase.dart';
import 'package:school_models/school_models.dart';

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    firestore: FirestoreClient(),
  );
});

class AttendanceRepository {
  AttendanceRepository({
    required FirestoreClient firestore,
  }) : _firestore = firestore;

  final FirestoreClient _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(
        FirestoreCollections.attendanceSessions,
      );

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(
        FirestoreCollections.attendanceRecords,
      );

  Future<List<AttendanceSession>> getSessions({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty ||
        sectionId.trim().isEmpty) {
      return <AttendanceSession>[];
    }

    final snapshot = await _sessions
        .where('schoolId', isEqualTo: schoolId.trim())
        .where('sectionId', isEqualTo: sectionId.trim())
        .get();

    final sessions = snapshot.docs
        .map(
          (doc) => AttendanceSession.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    sessions.sort((a, b) => b.date.compareTo(a.date));

    return sessions;
  }

  Future<List<AttendanceRecord>> getRecords({
    required String schoolId,
    required String sectionId,
    required DateTime date,
  }) async {
    if (schoolId.trim().isEmpty ||
        sectionId.trim().isEmpty) {
      return <AttendanceRecord>[];
    }

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _records
        .where('schoolId', isEqualTo: schoolId.trim())
        .where('sectionId', isEqualTo: sectionId.trim())
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .get();

    final records = snapshot.docs
        .map(
          (doc) => AttendanceRecord.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    records.sort(
      (a, b) => a.studentId.compareTo(b.studentId),
    );

    return records;
  }

  Future<void> saveAttendance({
    required String schoolId,
    required String classId,
    required String sectionId,
    required DateTime date,
    required String markedBy,
    required Map<String, String> studentStatuses,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedClassId = classId.trim();
    final normalizedSectionId = sectionId.trim();
    final normalizedMarkedBy = markedBy.trim();

    if (normalizedSchoolId.isEmpty ||
        normalizedClassId.isEmpty ||
        normalizedSectionId.isEmpty ||
        normalizedMarkedBy.isEmpty) {
      throw ArgumentError(
        'School, class, section aur teacher ki information required hai.',
      );
    }

    if (studentStatuses.isEmpty) {
      throw ArgumentError(
        'Attendance mark karne ke liye students required hain.',
      );
    }

    const allowedStatuses = {
      'present',
      'absent',
      'late',
      'leave',
    };

    for (final entry in studentStatuses.entries) {
      if (entry.key.trim().isEmpty ||
          !allowedStatuses.contains(entry.value)) {
        throw ArgumentError(
          'Student ID ya attendance status valid nahi hai.',
        );
      }
    }

    final attendanceDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final sessionId =
        '${normalizedSectionId}_${attendanceDate.year}'
        '${attendanceDate.month.toString().padLeft(2, '0')}'
        '${attendanceDate.day.toString().padLeft(2, '0')}';

    final sessionRef = _sessions.doc(sessionId);

    final existingRecords = await _records
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .where('sectionId', isEqualTo: normalizedSectionId)
        .where(
          'date',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(attendanceDate),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(
            attendanceDate.add(const Duration(days: 1)),
          ),
        )
        .get();

    final existingByStudent = <String, String>{
      for (final doc in existingRecords.docs)
        if (doc.data()['studentId'] is String)
          doc.data()['studentId'] as String: doc.id,
    };

    final batch = _firestore.instance.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(
      sessionRef,
      {
        'schoolId': normalizedSchoolId,
        'classId': normalizedClassId,
        'sectionId': normalizedSectionId,
        'date': Timestamp.fromDate(attendanceDate),
        'status': 'submitted',
        'markedBy': normalizedMarkedBy,
        'updatedAt': now,
        'createdAt': now,
      },
      SetOptions(merge: true),
    );

    for (final entry in studentStatuses.entries) {
      final studentId = entry.key.trim();

      final recordId =
          existingByStudent[studentId] ??
          '${sessionId}_$studentId';

      final recordRef = _records.doc(recordId);

      batch.set(
        recordRef,
        {
          'schoolId': normalizedSchoolId,
          'studentId': studentId,
          'classId': normalizedClassId,
          'sectionId': normalizedSectionId,
          'attendanceSessionId': sessionId,
          'date': Timestamp.fromDate(attendanceDate),
          'status': entry.value,
          'markedBy': normalizedMarkedBy,
          'updatedAt': now,
          'createdAt': now,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
