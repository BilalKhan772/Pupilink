class ExamDateSheet {
  final String id;
  final String schoolId;
  final String examId;
  final String examName;
  final String classId;
  final String sectionId;
  final String? academicYearId;
  final String subjectId;
  final String subjectName;
  final DateTime examDate;
  final String startTime;
  final String endTime;
  final String? roomNumber;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExamDateSheet({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.examName,
    required this.classId,
    required this.sectionId,
    this.academicYearId,
    required this.subjectId,
    required this.subjectName,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
    this.status = 'scheduled',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamDateSheet.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ExamDateSheet(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      examDate: _examSheetDateTime(map['examDate']) ??
          DateTime(2000),
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      roomNumber: map['roomNumber'] as String?,
      status: map['status'] as String? ?? 'scheduled',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _examSheetDateTime(map['createdAt']),
      updatedAt: _examSheetDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'examId': examId,
      'examName': examName,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examDate': examDate,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isScheduled => status == 'scheduled';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  ExamDateSheet copyWith({
    String? id,
    String? schoolId,
    String? examId,
    String? examName,
    String? classId,
    String? sectionId,
    String? academicYearId,
    String? subjectId,
    String? subjectName,
    DateTime? examDate,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamDateSheet(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _examSheetDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic timestamp = value;
    final DateTime date = timestamp.toDate() as DateTime;
    return date;
  } catch (_) {
    return null;
  }
}