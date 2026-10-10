
class Subject {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final String? description;
  final String? academicYearId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.description,
    this.academicYearId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Subject.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Subject(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String?,
      description: map['description'] as String?,
      academicYearId: map['academicYearId'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _subjectDate(map['createdAt']),
      updatedAt: _subjectDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'code': code,
      'description': description,
      'academicYearId': academicYearId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Subject copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? code,
    String? description,
    String? academicYearId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      academicYearId: academicYearId ?? this.academicYearId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _subjectDate(dynamic value) {
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
