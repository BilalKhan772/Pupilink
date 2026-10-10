
class AttendanceSummary {
  final String id;
  final String schoolId;
  final String studentId;
  final String? academicYearId;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final DateTime? updatedAt;

  const AttendanceSummary({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.academicYearId,
    this.totalDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.leaveDays = 0,
    this.updatedAt,
  });

  factory AttendanceSummary.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AttendanceSummary(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      totalDays: (map['totalDays'] as num?)?.toInt() ?? 0,
      presentDays: (map['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (map['absentDays'] as num?)?.toInt() ?? 0,
      lateDays: (map['lateDays'] as num?)?.toInt() ?? 0,
      leaveDays: (map['leaveDays'] as num?)?.toInt() ?? 0,
      updatedAt: _attendanceSummaryDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'academicYearId': academicYearId,
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'leaveDays': leaveDays,
      'updatedAt': updatedAt,
    };
  }

  double get attendancePercentage {
    if (totalDays <= 0) return 0;

    return (presentDays + lateDays) / totalDays * 100;
  }

  AttendanceSummary copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? academicYearId,
    int? totalDays,
    int? presentDays,
    int? absentDays,
    int? lateDays,
    int? leaveDays,
    DateTime? updatedAt,
  }) {
    return AttendanceSummary(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      academicYearId: academicYearId ?? this.academicYearId,
      totalDays: totalDays ?? this.totalDays,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      lateDays: lateDays ?? this.lateDays,
      leaveDays: leaveDays ?? this.leaveDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _attendanceSummaryDate(dynamic value) {
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
