class SubjectPerformance {
  final String id;
  final String schoolId;
  final String studentId;
  final String subjectId;
  final String subjectName;
  final String? academicYearId;
  final String? examId;
  final double totalMarks;
  final double obtainedMarks;
  final double percentage;
  final String? grade;
  final int examsCount;
  final String? teacherRemarks;
  final DateTime? lastExamDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubjectPerformance({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    this.academicYearId,
    this.examId,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percentage,
    this.grade,
    this.examsCount = 0,
    this.teacherRemarks,
    this.lastExamDate,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectPerformance.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SubjectPerformance(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      examId: map['examId'] as String?,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      obtainedMarks:
          (map['obtainedMarks'] as num?)?.toDouble() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
      grade: map['grade'] as String?,
      examsCount: (map['examsCount'] as num?)?.toInt() ?? 0,
      teacherRemarks: map['teacherRemarks'] as String?,
      lastExamDate: _subjectPerformanceDateTime(map['lastExamDate']),
      createdAt: _subjectPerformanceDateTime(map['createdAt']),
      updatedAt: _subjectPerformanceDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'academicYearId': academicYearId,
      'examId': examId,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'percentage': percentage,
      'grade': grade,
      'examsCount': examsCount,
      'teacherRemarks': teacherRemarks,
      'lastExamDate': lastExamDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get hasExamData => examsCount > 0;

  bool get hasValidMarks =>
      totalMarks > 0 &&
      obtainedMarks >= 0 &&
      obtainedMarks <= totalMarks;

  SubjectPerformance copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? subjectId,
    String? subjectName,
    String? academicYearId,
    String? examId,
    double? totalMarks,
    double? obtainedMarks,
    double? percentage,
    String? grade,
    int? examsCount,
    String? teacherRemarks,
    DateTime? lastExamDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectPerformance(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      academicYearId: academicYearId ?? this.academicYearId,
      examId: examId ?? this.examId,
      totalMarks: totalMarks ?? this.totalMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      examsCount: examsCount ?? this.examsCount,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
      lastExamDate: lastExamDate ?? this.lastExamDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _subjectPerformanceDateTime(dynamic value) {
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