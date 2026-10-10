
class SchoolSettings {
  final String schoolId;
  final bool attendanceEnabled;
  final bool homeworkEnabled;
  final bool resultsEnabled;
  final bool notificationsEnabled;
  final int lateAfterMinutes;
  final String attendanceMode;
  final DateTime? updatedAt;
  final String? updatedBy;

  const SchoolSettings({
    required this.schoolId,
    this.attendanceEnabled = true,
    this.homeworkEnabled = true,
    this.resultsEnabled = true,
    this.notificationsEnabled = true,
    this.lateAfterMinutes = 10,
    this.attendanceMode = 'manual',
    this.updatedAt,
    this.updatedBy,
  });

  factory SchoolSettings.fromMap(
    String schoolId,
    Map<String, dynamic> map,
  ) {
    return SchoolSettings(
      schoolId: schoolId,
      attendanceEnabled:
          map['attendanceEnabled'] as bool? ?? true,
      homeworkEnabled:
          map['homeworkEnabled'] as bool? ?? true,
      resultsEnabled:
          map['resultsEnabled'] as bool? ?? true,
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? true,
      lateAfterMinutes:
          map['lateAfterMinutes'] as int? ?? 10,
      attendanceMode:
          map['attendanceMode'] as String? ?? 'manual',
      updatedAt: _settingsDateTime(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceEnabled': attendanceEnabled,
      'homeworkEnabled': homeworkEnabled,
      'resultsEnabled': resultsEnabled,
      'notificationsEnabled': notificationsEnabled,
      'lateAfterMinutes': lateAfterMinutes,
      'attendanceMode': attendanceMode,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  SchoolSettings copyWith({
    String? schoolId,
    bool? attendanceEnabled,
    bool? homeworkEnabled,
    bool? resultsEnabled,
    bool? notificationsEnabled,
    int? lateAfterMinutes,
    String? attendanceMode,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SchoolSettings(
      schoolId: schoolId ?? this.schoolId,
      attendanceEnabled:
          attendanceEnabled ?? this.attendanceEnabled,
      homeworkEnabled: homeworkEnabled ?? this.homeworkEnabled,
      resultsEnabled: resultsEnabled ?? this.resultsEnabled,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      lateAfterMinutes: lateAfterMinutes ?? this.lateAfterMinutes,
      attendanceMode: attendanceMode ?? this.attendanceMode,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

DateTime? _settingsDateTime(dynamic value) {
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
