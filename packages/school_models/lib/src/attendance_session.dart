
class AttendanceSession {
  final String id;
  final String schoolId;
  final String classId;
  final String sectionId;
  final String? academicYearId;
  final DateTime date;
  final String status;
  final String? markedBy;
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceSession({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.sectionId,
    this.academicYearId,
    required this.date,
    this.status = 'draft',
    this.markedBy,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceSession.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AttendanceSession(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      date: _attendanceSessionDate(map['date']) ??
          DateTime(2000, 1, 1),
      status: map['status'] as String? ?? 'draft',
      markedBy: map['markedBy'] as String?,
      submittedAt:
          _attendanceSessionDate(map['submittedAt']),
      createdAt: _attendanceSessionDate(map['createdAt']),
      updatedAt: _attendanceSessionDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'date': date,
      'status': status,
      'markedBy': markedBy,
      'submittedAt': submittedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isDraft => status == 'draft';

  bool get isSubmitted => status == 'submitted';

  AttendanceSession copyWith({
    String? id,
    String? schoolId,
    String? classId,
    String? sectionId,
    String? academicYearId,
    DateTime? date,
    String? status,
    String? markedBy,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _attendanceSessionDate(dynamic value) {
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
