class Timetable {
  final String id;
  final String schoolId;
  final String name;
  final String classId;
  final String sectionId;
  final String? academicYearId;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Timetable({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.classId,
    required this.sectionId,
    this.academicYearId,
    this.effectiveFrom,
    this.effectiveTo,
    this.status = 'active',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Timetable.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Timetable(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      effectiveFrom: map['effectiveFrom'] as String?,
      effectiveTo: map['effectiveTo'] as String?,
      status: map['status'] as String? ?? 'active',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _timetableDateTime(map['createdAt']),
      updatedAt: _timetableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'effectiveFrom': effectiveFrom,
      'effectiveTo': effectiveTo,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isActive => status == 'active';

  bool get isDraft => status == 'draft';

  bool get isArchived => status == 'archived';

  Timetable copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? classId,
    String? sectionId,
    String? academicYearId,
    String? effectiveFrom,
    String? effectiveTo,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timetable(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _timetableDateTime(dynamic value) {
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