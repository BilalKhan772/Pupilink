class TimetablePeriod {
  final String id;
  final String schoolId;
  final String timetableId;
  final String classId;
  final String sectionId;
  final String? subjectId;
  final String subjectName;
  final String? teacherId;
  final String? teacherName;
  final int periodNumber;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomNumber;
  final bool isBreak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TimetablePeriod({
    required this.id,
    required this.schoolId,
    required this.timetableId,
    required this.classId,
    required this.sectionId,
    this.subjectId,
    required this.subjectName,
    this.teacherId,
    this.teacherName,
    required this.periodNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
    this.isBreak = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TimetablePeriod.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TimetablePeriod(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      timetableId: map['timetableId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subjectId: map['subjectId'] as String?,
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String?,
      teacherName: map['teacherName'] as String?,
      periodNumber: (map['periodNumber'] as num?)?.toInt() ?? 0,
      dayOfWeek: map['dayOfWeek'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      roomNumber: map['roomNumber'] as String?,
      isBreak: map['isBreak'] as bool? ?? false,
      createdAt: _periodDateTime(map['createdAt']),
      updatedAt: _periodDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'timetableId': timetableId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'periodNumber': periodNumber,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      'isBreak': isBreak,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isTeachingPeriod => !isBreak;

  TimetablePeriod copyWith({
    String? id,
    String? schoolId,
    String? timetableId,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    int? periodNumber,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? roomNumber,
    bool? isBreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetablePeriod(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      timetableId: timetableId ?? this.timetableId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      periodNumber: periodNumber ?? this.periodNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      isBreak: isBreak ?? this.isBreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _periodDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  // Supports Firestore Timestamp without importing Firebase packages.
  try {
    final dynamic timestamp = value;
    final DateTime date = timestamp.toDate() as DateTime;
    return date;
  } catch (_) {
    return null;
  }
}
