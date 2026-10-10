
class AcademicYear {
  final String id;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AcademicYear({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicYear.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AcademicYear(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startDate: _academicYearDate(map['startDate']) ??
          DateTime(2000, 1, 1),
      endDate: _academicYearDate(map['endDate']) ??
          DateTime(2000, 12, 31),
      isCurrent: map['isCurrent'] as bool? ?? false,
      status: map['status'] as String? ?? 'active',
      createdAt: _academicYearDate(map['createdAt']),
      updatedAt: _academicYearDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isDateRangeValid =>
      !endDate.isBefore(startDate);

  bool get isWithinDateRange {
    final now = DateTime.now();
    return !now.isBefore(startDate) &&
        !now.isAfter(endDate);
  }

  AcademicYear copyWith({
    String? id,
    String? schoolId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _academicYearDate(dynamic value) {
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
