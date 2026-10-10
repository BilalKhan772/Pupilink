class SchoolTest {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String subjectName;
  final String? academicYearId;
  final String testType;
  final DateTime testDate;
  final String startTime;
  final String endTime;
  final double totalMarks;
  final double passingMarks;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolTest({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description = '',
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    this.academicYearId,
    this.testType = 'classTest',
    required this.testDate,
    required this.startTime,
    required this.endTime,
    required this.totalMarks,
    required this.passingMarks,
    this.status = 'scheduled',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolTest.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SchoolTest(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      testType: map['testType'] as String? ?? 'classTest',
      testDate: _schoolTestDateTime(map['testDate']) ??
          DateTime(2000),
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'scheduled',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _schoolTestDateTime(map['createdAt']),
      updatedAt: _schoolTestDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'academicYearId': academicYearId,
      'testType': testType,
      'testDate': testDate,
      'startTime': startTime,
      'endTime': endTime,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isScheduled => status == 'scheduled';

  bool get isPublished => status == 'published';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isValidMarks =>
      totalMarks > 0 &&
      passingMarks >= 0 &&
      passingMarks <= totalMarks;

  SchoolTest copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? description,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? subjectName,
    String? academicYearId,
    String? testType,
    DateTime? testDate,
    String? startTime,
    String? endTime,
    double? totalMarks,
    double? passingMarks,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolTest(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      academicYearId: academicYearId ?? this.academicYearId,
      testType: testType ?? this.testType,
      testDate: testDate ?? this.testDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _schoolTestDateTime(dynamic value) {
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