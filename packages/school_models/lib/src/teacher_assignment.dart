
class TeacherAssignment {
  final String id;
  final String schoolId;
  final String teacherId;
  final String classId;
  final String? sectionId;
  final String? subjectId;
  final String? academicYearId;
  final String assignmentType;
  final bool isActive;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeacherAssignment({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.classId,
    this.sectionId,
    this.subjectId,
    this.academicYearId,
    this.assignmentType = 'subjectTeacher',
    this.isActive = true,
    this.assignedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherAssignment.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TeacherAssignment(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String?,
      subjectId: map['subjectId'] as String?,
      academicYearId: map['academicYearId'] as String?,
      assignmentType:
          map['assignmentType'] as String? ?? 'subjectTeacher',
      isActive: map['isActive'] as bool? ?? true,
      assignedAt: _teacherAssignmentDate(map['assignedAt']),
      createdAt: _teacherAssignmentDate(map['createdAt']),
      updatedAt: _teacherAssignmentDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'teacherId': teacherId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'academicYearId': academicYearId,
      'assignmentType': assignmentType,
      'isActive': isActive,
      'assignedAt': assignedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  TeacherAssignment copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? academicYearId,
    String? assignmentType,
    bool? isActive,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      academicYearId: academicYearId ?? this.academicYearId,
      assignmentType: assignmentType ?? this.assignmentType,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _teacherAssignmentDate(dynamic value) {
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
