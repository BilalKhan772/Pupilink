
class SchoolSection {
  final String id;
  final String schoolId;
  final String classId;
  final String name;
  final String? academicYearId;
  final String? classTeacherId;
  final int? capacity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolSection({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.name,
    this.academicYearId,
    this.classTeacherId,
    this.capacity,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolSection.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SchoolSection(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      classTeacherId: map['classTeacherId'] as String?,
      capacity: (map['capacity'] as num?)?.toInt(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _schoolSectionDate(map['createdAt']),
      updatedAt: _schoolSectionDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'name': name,
      'academicYearId': academicYearId,
      'classTeacherId': classTeacherId,
      'capacity': capacity,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SchoolSection copyWith({
    String? id,
    String? schoolId,
    String? classId,
    String? name,
    String? academicYearId,
    String? classTeacherId,
    int? capacity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolSection(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      academicYearId: academicYearId ?? this.academicYearId,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _schoolSectionDate(dynamic value) {
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
