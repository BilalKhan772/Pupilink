import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableRepository {
  TimetableRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _timetable =>
      _firestore.collection('timetable');

  Future<List<Map<String, dynamic>>> getTimetable({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError('School ID aur Section ID required hain.');
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
      final dayCompare = _dayOrder(a['day'] as String?)
          .compareTo(_dayOrder(b['day'] as String?));

      if (dayCompare != 0) return dayCompare;

      return (a['startTime'] as String? ?? '')
          .compareTo(b['startTime'] as String? ?? '');
    });

    return records;
  }

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
      throw ArgumentError('Tamam required fields fill karein.');
    }

    if (_timeToMinutes(endTime) <= _timeToMinutes(startTime)) {
      throw ArgumentError('End time, start time ke baad hona chahiye.');
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
      final existing = await _timetable.doc(entryId).get();

      if (!existing.exists ||
          existing.data()?['schoolId'] != schoolId.trim() ||
          existing.data()?['sectionId'] != sectionId.trim()) {
        throw Exception('Timetable entry nahi mili ya access match nahi karta.');
      }

      await _timetable.doc(entryId).update(data);
    }
  }

  Future<void> deleteTimetableEntry({
    required String entryId,
    required String schoolId,
    required String sectionId,
  }) async {
    final ref = _timetable.doc(entryId);
    final snapshot = await ref.get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != schoolId ||
        snapshot.data()?['sectionId'] != sectionId) {
      throw Exception('Entry nahi mili ya access match nahi karta.');
    }

    await ref.delete();
  }

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

  static int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      throw ArgumentError('Time format HH:mm hona chahiye.');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Time valid nahi hai.');
    }

    return hour * 60 + minute;
  }
}