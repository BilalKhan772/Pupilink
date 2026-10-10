class StudentResultSummary {
  final String id;
  final String schoolId;
  final String studentId;
  final String examId;
  final String examName;
  final String classId;
  final String sectionId;
  final String? academicYearId;
  final double totalMarks;
  final double obtainedMarks;
  final double percentage;
  final String? grade;
  final String resultStatus;
  final int totalSubjects;
  final int passedSubjects;
  final int failedSubjects;
  final String? remarks;
  final String publishedBy;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentResultSummary({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.examId,
    required this.examName,
    required this.classId,
    required this.sectionId,
    this.academicYearId,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percentage,
    this.grade,
    this.resultStatus = 'pending',
    this.totalSubjects = 0,
    this.passedSubjects = 0,
    this.failedSubjects = 0,
    this.remarks,
    required this.publishedBy,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentResultSummary.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return StudentResultSummary(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      obtainedMarks:
          (map['obtainedMarks'] as num?)?.toDouble() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
      grade: map['grade'] as String?,
      resultStatus: map['resultStatus'] as String? ?? 'pending',
      totalSubjects: (map['totalSubjects'] as num?)?.toInt() ?? 0,
      passedSubjects: (map['passedSubjects'] as num?)?.toInt() ?? 0,
      failedSubjects: (map['failedSubjects'] as num?)?.toInt() ?? 0,
      remarks: map['remarks'] as String?,
      publishedBy: map['publishedBy'] as String? ?? '',
      publishedAt: _resultSummaryDateTime(map['publishedAt']),
      createdAt: _resultSummaryDateTime(map['createdAt']),
      updatedAt: _resultSummaryDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'examId': examId,
      'examName': examName,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'percentage': percentage,
      'grade': grade,
      'resultStatus': resultStatus,
      'totalSubjects': totalSubjects,
      'passedSubjects': passedSubjects,
      'failedSubjects': failedSubjects,
      'remarks': remarks,
      'publishedBy': publishedBy,
      'publishedAt': publishedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isPassed => resultStatus == 'passed';

  bool get isFailed => resultStatus == 'failed';

  bool get isPublished => publishedAt != null;

  StudentResultSummary copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? examId,
    String? examName,
    String? classId,
    String? sectionId,
    String? academicYearId,
    double? totalMarks,
    double? obtainedMarks,
    double? percentage,
    String? grade,
    String? resultStatus,
    int? totalSubjects,
    int? passedSubjects,
    int? failedSubjects,
    String? remarks,
    String? publishedBy,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentResultSummary(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      totalMarks: totalMarks ?? this.totalMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      resultStatus: resultStatus ?? this.resultStatus,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      passedSubjects: passedSubjects ?? this.passedSubjects,
      failedSubjects: failedSubjects ?? this.failedSubjects,
      remarks: remarks ?? this.remarks,
      publishedBy: publishedBy ?? this.publishedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _resultSummaryDateTime(dynamic value) {
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