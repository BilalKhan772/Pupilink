
class SchoolClass {
  final String id;
  final String schoolId;
  final String name;
  final String? academicYearId;
  final int? sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.academicYearId,
    this.sortOrder,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolClass.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SchoolClass(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      academicYearId: map['academicYearId'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _schoolClassDate(map['createdAt']),
      updatedAt: _schoolClassDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'academicYearId': academicYearId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SchoolClass copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? academicYearId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      academicYearId: academicYearId ?? this.academicYearId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _schoolClassDate(dynamic value) {
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
