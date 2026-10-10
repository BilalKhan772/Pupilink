
class AttendanceRecord {
  final String id;
  final String schoolId;
  final String studentId;
  final String classId;
  final String sectionId;
  final String? attendanceSessionId;
  final DateTime date;
  final String status;
  final String? remarks;
  final String? markedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.sectionId,
    this.attendanceSessionId,
    required this.date,
    required this.status,
    this.remarks,
    this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AttendanceRecord(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      attendanceSessionId:
          map['attendanceSessionId'] as String?,
      date: _attendanceRecordDate(map['date']) ??
          DateTime(2000, 1, 1),
      status: map['status'] as String? ?? 'absent',
      remarks: map['remarks'] as String?,
      markedBy: map['markedBy'] as String?,
      createdAt: _attendanceRecordDate(map['createdAt']),
      updatedAt: _attendanceRecordDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'classId': classId,
      'sectionId': sectionId,
      'attendanceSessionId': attendanceSessionId,
      'date': date,
      'status': status,
      'remarks': remarks,
      'markedBy': markedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isPresent => status == 'present';

  bool get isAbsent => status == 'absent';

  bool get isLate => status == 'late';

  bool get isLeave => status == 'leave';

  AttendanceRecord copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? classId,
    String? sectionId,
    String? attendanceSessionId,
    DateTime? date,
    String? status,
    String? remarks,
    String? markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      attendanceSessionId:
          attendanceSessionId ?? this.attendanceSessionId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _attendanceRecordDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  try {
    final dynamic result = value.toDate();
    if (result is DateTime) return result;
  } catch (_) {
    // Unsupported date format.
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
