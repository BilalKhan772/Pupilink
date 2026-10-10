class StudentMark {
  final String id;
  final String schoolId;
  final String studentId;
  final String examId;
  final String? examPaperId;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String subjectName;
  final String? academicYearId;
  final double obtainedMarks;
  final double totalMarks;
  final String? grade;
  final String? remarks;
  final String status;
  final String enteredBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentMark({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.examId,
    this.examPaperId,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    this.academicYearId,
    required this.obtainedMarks,
    required this.totalMarks,
    this.grade,
    this.remarks,
    this.status = 'draft',
    required this.enteredBy,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentMark.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return StudentMark(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examPaperId: map['examPaperId'] as String?,
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      obtainedMarks:
          (map['obtainedMarks'] as num?)?.toDouble() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      grade: map['grade'] as String?,
      remarks: map['remarks'] as String?,
      status: map['status'] as String? ?? 'draft',
      enteredBy: map['enteredBy'] as String? ?? '',
      createdAt: _studentMarkDateTime(map['createdAt']),
      updatedAt: _studentMarkDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'examId': examId,
      'examPaperId': examPaperId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'academicYearId': academicYearId,
      'obtainedMarks': obtainedMarks,
      'totalMarks': totalMarks,
      'grade': grade,
      'remarks': remarks,
      'status': status,
      'enteredBy': enteredBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  double get percentage {
    if (totalMarks <= 0) return 0;

    return (obtainedMarks / totalMarks) * 100;
  }

  bool get isValidMarks =>
      totalMarks > 0 &&
      obtainedMarks >= 0 &&
      obtainedMarks <= totalMarks;

  bool get isDraft => status == 'draft';

  bool get isPublished => status == 'published';

  StudentMark copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? examId,
    String? examPaperId,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? subjectName,
    String? academicYearId,
    double? obtainedMarks,
    double? totalMarks,
    String? grade,
    String? remarks,
    String? status,
    String? enteredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentMark(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      examId: examId ?? this.examId,
      examPaperId: examPaperId ?? this.examPaperId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      academicYearId: academicYearId ?? this.academicYearId,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      enteredBy: enteredBy ?? this.enteredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _studentMarkDateTime(dynamic value) {
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