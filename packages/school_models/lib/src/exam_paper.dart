class ExamPaper {
  final String id;
  final String schoolId;
  final String examId;
  final String examName;
  final String classId;
  final String subjectId;
  final String subjectName;
  final String? academicYearId;
  final double totalMarks;
  final double passingMarks;
  final int durationMinutes;
  final String? instructions;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExamPaper({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.examName,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    this.academicYearId,
    required this.totalMarks,
    required this.passingMarks,
    required this.durationMinutes,
    this.instructions,
    this.status = 'draft',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamPaper.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ExamPaper(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0,
      durationMinutes:
          (map['durationMinutes'] as num?)?.toInt() ?? 0,
      instructions: map['instructions'] as String?,
      status: map['status'] as String? ?? 'draft',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _examPaperDateTime(map['createdAt']),
      updatedAt: _examPaperDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'examId': examId,
      'examName': examName,
      'classId': classId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'academicYearId': academicYearId,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'durationMinutes': durationMinutes,
      'instructions': instructions,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isDraft => status == 'draft';

  bool get isPublished => status == 'published';

  bool get isValidMarks =>
      totalMarks > 0 &&
      passingMarks >= 0 &&
      passingMarks <= totalMarks;

  ExamPaper copyWith({
    String? id,
    String? schoolId,
    String? examId,
    String? examName,
    String? classId,
    String? subjectId,
    String? subjectName,
    String? academicYearId,
    double? totalMarks,
    double? passingMarks,
    int? durationMinutes,
    String? instructions,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamPaper(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      academicYearId: academicYearId ?? this.academicYearId,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      instructions: instructions ?? this.instructions,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _examPaperDateTime(dynamic value) {
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