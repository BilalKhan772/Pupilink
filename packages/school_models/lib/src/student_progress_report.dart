
class StudentProgressReport {
  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String classId;
  final String sectionId;
  final String? academicYearId;
  final String reportTitle;
  final String reportingPeriod;
  final double attendancePercentage;
  final double academicPercentage;
  final String? overallGrade;
  final String overallStatus;
  final String teacherRemarks;
  final String? strengths;
  final String? areasForImprovement;
  final String? recommendations;
  final String preparedBy;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentProgressReport({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.sectionId,
    this.academicYearId,
    required this.reportTitle,
    required this.reportingPeriod,
    this.attendancePercentage = 0,
    this.academicPercentage = 0,
    this.overallGrade,
    this.overallStatus = 'draft',
    this.teacherRemarks = '',
    this.strengths,
    this.areasForImprovement,
    this.recommendations,
    required this.preparedBy,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentProgressReport.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return StudentProgressReport(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      reportTitle: map['reportTitle'] as String? ?? '',
      reportingPeriod: map['reportingPeriod'] as String? ?? '',
      attendancePercentage:
          (map['attendancePercentage'] as num?)?.toDouble() ?? 0,
      academicPercentage:
          (map['academicPercentage'] as num?)?.toDouble() ?? 0,
      overallGrade: map['overallGrade'] as String?,
      overallStatus: map['overallStatus'] as String? ?? 'draft',
      teacherRemarks: map['teacherRemarks'] as String? ?? '',
      strengths: map['strengths'] as String?,
      areasForImprovement: map['areasForImprovement'] as String?,
      recommendations: map['recommendations'] as String?,
      preparedBy: map['preparedBy'] as String? ?? '',
      publishedAt: _progressReportDateTime(map['publishedAt']),
      createdAt: _progressReportDateTime(map['createdAt']),
      updatedAt: _progressReportDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'reportTitle': reportTitle,
      'reportingPeriod': reportingPeriod,
      'attendancePercentage': attendancePercentage,
      'academicPercentage': academicPercentage,
      'overallGrade': overallGrade,
      'overallStatus': overallStatus,
      'teacherRemarks': teacherRemarks,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
      'recommendations': recommendations,
      'preparedBy': preparedBy,
      'publishedAt': publishedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isDraft => overallStatus == 'draft';

  bool get isPublished => overallStatus == 'published';

  bool get hasValidPercentages =>
      attendancePercentage >= 0 &&
      attendancePercentage <= 100 &&
      academicPercentage >= 0 &&
      academicPercentage <= 100;

  StudentProgressReport copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? studentName,
    String? classId,
    String? sectionId,
    String? academicYearId,
    String? reportTitle,
    String? reportingPeriod,
    double? attendancePercentage,
    double? academicPercentage,
    String? overallGrade,
    String? overallStatus,
    String? teacherRemarks,
    String? strengths,
    String? areasForImprovement,
    String? recommendations,
    String? preparedBy,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProgressReport(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportingPeriod: reportingPeriod ?? this.reportingPeriod,
      attendancePercentage:
          attendancePercentage ?? this.attendancePercentage,
      academicPercentage:
          academicPercentage ?? this.academicPercentage,
      overallGrade: overallGrade ?? this.overallGrade,
      overallStatus: overallStatus ?? this.overallStatus,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
      strengths: strengths ?? this.strengths,
      areasForImprovement:
          areasForImprovement ?? this.areasForImprovement,
      recommendations: recommendations ?? this.recommendations,
      preparedBy: preparedBy ?? this.preparedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _progressReportDateTime(dynamic value) {
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